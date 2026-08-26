import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { QuotationStatus, InvoiceStatus, PaymentMethod, NotificationChannel } from '@prisma/client';
import * as PDFDocument from 'pdfkit';
import * as fs from 'fs';
import * as path from 'path';

export interface CreateQuotationDto {
  customerId: string;
  jobId?: string;
  isGst?: boolean;
  framingCharges?: number;
  installationCharges?: number;
  discountAmount?: number;
  gstPercentage?: number;
  termsAndConditions?: string;
  items: Array<{
    itemDescription: string;
    lengthFeet: number;
    heightFeet: number;
    unitRate: number;
    materialType?: string;
  }>;
}

@Injectable()
export class QuotationsService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
    private notificationsService: NotificationsService,
    private whatsappService: WhatsAppService,
  ) {}

  async findAll() {
    return this.prisma.quotation.findMany({
      include: {
        customer: true,
        job: { select: { id: true, jobCode: true, boardType: true } },
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const quotation = await this.prisma.quotation.findUnique({
      where: { id },
      include: {
        customer: true,
        job: true,
        items: true,
        invoices: true,
      },
    });
    if (!quotation) throw new NotFoundException('Quotation not found');
    return quotation;
  }

  async create(dto: CreateQuotationDto) {
    const customer = await this.prisma.customer.findUnique({ where: { id: dto.customerId } });
    if (!customer) throw new NotFoundException('Customer not found');

    const year = new Date().getFullYear();
    const count = await this.prisma.quotation.count();
    const quoteNumber = `QT-${year}-${String(count + 1).padStart(4, '0')}`;

    // Perform centralized calculation
    const calc = this.calculationService.calculateQuotation(
      dto.items,
      dto.framingCharges || 0,
      dto.installationCharges || 0,
      dto.discountAmount || 0,
      dto.isGst ?? true,
      dto.gstPercentage || 18.0,
    );

    const quotation = await this.prisma.quotation.create({
      data: {
        quoteNumber,
        customerId: dto.customerId,
        jobId: dto.jobId,
        isGst: dto.isGst ?? true,
        subtotalAmount: calc.subtotalAmount,
        framingCharges: calc.framingCharges,
        installationCharges: calc.installationCharges,
        gstPercentage: calc.gstPercentage,
        gstAmount: calc.gstAmount,
        discountAmount: calc.discountAmount,
        totalAmount: calc.totalAmount,
        status: QuotationStatus.DRAFT,
        termsAndConditions: dto.termsAndConditions || '1. 50% Advance with order.\n2. Balance on installation completion.',
      },
    });

    for (const item of calc.items) {
      await this.prisma.quotationItem.create({
        data: {
          quotationId: quotation.id,
          itemDescription: item.itemDescription,
          lengthFeet: item.lengthFeet,
          heightFeet: item.heightFeet,
          totalSqFt: item.totalSqFt,
          unitRate: item.unitRate,
          amount: item.amount,
        },
      });
    }

    // Generate Branded PDF
    const pdfFileName = `quotation_${quoteNumber}.pdf`;
    const uploadDir = process.env.UPLOAD_DESTINATION || './uploads';
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    const pdfPath = path.join(uploadDir, pdfFileName);

    await this.generateDocumentPdf(pdfPath, 'ESTIMATE / QUOTATION', quoteNumber, customer, calc, quotation.termsAndConditions);

    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    const pdfUrl = `${appUrl}/uploads/${pdfFileName}`;

    return this.prisma.quotation.update({
      where: { id: quotation.id },
      data: { pdfUrl },
      include: { customer: true, items: true },
    });
  }

  async sendViaWhatsApp(id: string) {
    const quotation = await this.findOne(id);
    if (!quotation.customer.phone) {
      throw new BadRequestException('Customer has no phone number recorded');
    }

    await this.whatsappService.sendMessage({
      toPhone: quotation.customer.phone,
      messageText: `Dear ${quotation.customer.name}, please find attached your Signage Quotation *#${quotation.quoteNumber}* for *₹${quotation.totalAmount.toLocaleString()}*.\n\nDownload PDF: ${quotation.pdfUrl}\n\n- Apex Signage`,
      mediaUrl: quotation.pdfUrl,
    });

    return this.prisma.quotation.update({
      where: { id },
      data: { status: QuotationStatus.SENT },
    });
  }

  private async generateDocumentPdf(
    filePath: string,
    docTitle: string,
    docNumber: string,
    customer: any,
    calc: any,
    terms?: string,
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const writeStream = fs.createWriteStream(filePath);
      doc.pipe(writeStream);

      // Header Branding
      doc.fillColor('#002B49').fontSize(22).text('APEX SIGNAGE & PRINTING SOLUTIONS', 40, 40);
      doc.fontSize(9).fillColor('#666666').text('Plot 42, Industrial Area Phase 2, Mumbai 400093 | GSTIN: 27AABCS1429B1Z8', 40, 68);
      doc.text('Phone: +91 98765 00000 | Email: billing@apexsignage.com', 40, 80);

      doc.moveTo(40, 98).lineTo(555, 98).strokeColor('#002B49').lineWidth(2).stroke();
      doc.moveDown(1.5);

      // Document Title & Metadata
      doc.fillColor('#111827').fontSize(14).text(docTitle, 40, 110);
      doc.fontSize(10).text(`Number: ${docNumber}`, 40, 130);
      doc.text(`Date  : ${new Date().toLocaleDateString('en-IN')}`, 40, 144);

      // Customer Details (Right Aligned)
      doc.text('BILL TO / CLIENT:', 350, 110);
      doc.font('Helvetica-Bold').text(customer.name, 350, 124);
      doc.font('Helvetica').text(customer.companyName || '', 350, 138);
      doc.text(`Phone: ${customer.phone}`, 350, 152);
      if (customer.gstNumber) doc.text(`GSTIN: ${customer.gstNumber}`, 350, 166);

      // Table Header
      const tableTop = 190;
      doc.rect(40, tableTop, 515, 20).fill('#002B49');
      doc.fillColor('#FFFFFF').fontSize(9);
      doc.text('ITEM DESCRIPTION', 45, tableTop + 6);
      doc.text('DIMENSIONS (W x H)', 230, tableTop + 6);
      doc.text('SQ.FT', 350, tableTop + 6);
      doc.text('RATE (₹)', 410, tableTop + 6);
      doc.text('TOTAL (₹)', 485, tableTop + 6);

      let currentY = tableTop + 24;
      doc.fillColor('#111827');
      for (const item of calc.items) {
        doc.text(item.itemDescription, 45, currentY, { width: 175 });
        doc.text(`${item.lengthFeet}' x ${item.heightFeet}'`, 230, currentY);
        doc.text(item.totalSqFt.toString(), 350, currentY);
        doc.text(`₹${item.unitRate}`, 410, currentY);
        doc.text(`₹${item.amount.toLocaleString()}`, 485, currentY);
        currentY += 24;
      }

      // Summary Box
      currentY = Math.max(currentY + 10, 360);
      doc.moveTo(320, currentY).lineTo(555, currentY).strokeColor('#E2E8F0').lineWidth(1).stroke();
      currentY += 8;

      const summaryLines = [
        ['Subtotal Amount', `Rs. ${calc.subtotalAmount.toLocaleString()}`],
        ['Framing & MS Structure', `+ Rs. ${calc.framingCharges.toLocaleString()}`],
        ['Installation & Labor', `+ Rs. ${calc.installationCharges.toLocaleString()}`],
        ['Discount', `- Rs. ${calc.discountAmount.toLocaleString()}`],
        [`GST (${calc.gstPercentage}%)`, `+ Rs. ${calc.gstAmount.toLocaleString()}`],
      ];

      for (const [label, val] of summaryLines) {
        doc.fontSize(9).text(label, 330, currentY);
        doc.text(val, 460, currentY, { align: 'right' });
        currentY += 16;
      }

      doc.rect(320, currentY, 235, 24).fill('#002B49');
      doc.fillColor('#FFFFFF').fontSize(11).text('GRAND TOTAL:', 330, currentY + 6);
      doc.fontSize(12).text(`Rs. ${calc.totalAmount.toLocaleString()}`, 450, currentY + 5, { align: 'right' });

      // Terms & Conditions
      doc.fillColor('#111827').fontSize(10).text('Terms & Conditions:', 40, currentY + 40);
      doc.fontSize(8).fillColor('#666666').text(terms || 'Standard terms apply.', 40, currentY + 54, { width: 515 });

      doc.end();
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });
  }
}
