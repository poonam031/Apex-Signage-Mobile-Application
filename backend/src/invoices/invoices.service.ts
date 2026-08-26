import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { InvoiceStatus, PaymentMethod } from '@prisma/client';
import * as PDFDocument from 'pdfkit';
import * as fs from 'fs';
import * as path from 'path';

export interface CreateInvoiceFromQuotationDto {
  quotationId: string;
  dueDate?: string | Date;
}

export interface DirectCreateInvoiceDto {
  customerId: string;
  jobId?: string;
  isGst?: boolean;
  framingCharges?: number;
  installationCharges?: number;
  discountAmount?: number;
  gstPercentage?: number;
  items: Array<{
    itemDescription: string;
    totalSqFt: number;
    unitRate: number;
  }>;
  dueDate?: string | Date;
}

@Injectable()
export class InvoicesService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
    private whatsappService: WhatsAppService,
  ) {}

  async findAll(status?: InvoiceStatus, customerId?: string) {
    return this.prisma.invoice.findMany({
      where: {
        ...(status ? { status } : {}),
        ...(customerId ? { customerId } : {}),
      },
      include: {
        customer: true,
        job: { select: { id: true, jobCode: true, boardType: true } },
        payments: true,
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
      include: {
        customer: true,
        job: true,
        quotation: true,
        items: true,
        payments: {
          include: { receivedBy: { select: { id: true, name: true } } },
          orderBy: { paymentDate: 'desc' },
        },
      },
    });
    if (!invoice) throw new NotFoundException('Invoice not found');
    return invoice;
  }

  async createFromQuotation(dto: CreateInvoiceFromQuotationDto) {
    const quotation = await this.prisma.quotation.findUnique({
      where: { id: dto.quotationId },
      include: { customer: true, items: true },
    });
    if (!quotation) throw new NotFoundException('Quotation not found');

    const year = new Date().getFullYear();
    const count = await this.prisma.invoice.count();
    const invoiceNumber = `INV-${year}-${String(count + 1).padStart(4, '0')}`;

    const invoice = await this.prisma.invoice.create({
      data: {
        invoiceNumber,
        quotationId: quotation.id,
        customerId: quotation.customerId,
        jobId: quotation.jobId,
        isGst: quotation.isGst,
        subtotalAmount: quotation.subtotalAmount,
        framingCharges: quotation.framingCharges,
        installationCharges: quotation.installationCharges,
        gstPercentage: quotation.gstPercentage,
        gstAmount: quotation.gstAmount,
        discountAmount: quotation.discountAmount,
        totalAmount: quotation.totalAmount,
        paidAmount: 0.0,
        pendingBalance: quotation.totalAmount,
        status: InvoiceStatus.UNPAID,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : new Date(Date.now() + 7 * 24 * 3600 * 1000),
      },
    });

    for (const item of quotation.items) {
      await this.prisma.invoiceItem.create({
        data: {
          invoiceId: invoice.id,
          itemDescription: item.itemDescription,
          totalSqFt: item.totalSqFt,
          unitRate: item.unitRate,
          amount: item.amount,
        },
      });
    }

    // Generate Invoice PDF
    const pdfFileName = `invoice_${invoiceNumber}.pdf`;
    const uploadDir = process.env.UPLOAD_DESTINATION || './uploads';
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    const pdfPath = path.join(uploadDir, pdfFileName);

    await this.generateInvoicePdf(pdfPath, invoiceNumber, quotation.customer, invoice, quotation.items);

    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    const invoicePdfUrl = `${appUrl}/uploads/${pdfFileName}`;

    return this.prisma.invoice.update({
      where: { id: invoice.id },
      data: { invoicePdfUrl },
      include: { customer: true, items: true },
    });
  }

  async sendInvoiceWhatsApp(id: string) {
    const invoice = await this.findOne(id);
    return this.whatsappService.sendInvoicePdf(
      invoice.customer.phone,
      invoice.customer.name,
      invoice.invoiceNumber,
      invoice.totalAmount,
      invoice.invoicePdfUrl || '',
    );
  }

  async sendPaymentReminder(id: string) {
    const invoice = await this.findOne(id);
    if (invoice.pendingBalance <= 0) {
      throw new BadRequestException('Invoice is already fully paid');
    }

    const messageText = `Gentle Reminder: Invoice *#${invoice.invoiceNumber}* has a pending balance of *₹${invoice.pendingBalance.toLocaleString()}*.\n\nKindly clear the payment at your earliest convenience.\n\nThank you,\nApex Signage Accounts`;
    return this.whatsappService.sendMessage({
      toPhone: invoice.customer.phone,
      messageText,
    });
  }

  private async generateInvoicePdf(
    filePath: string,
    invoiceNumber: string,
    customer: any,
    invoice: any,
    items: any[],
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
      doc.fillColor('#111827').fontSize(15).text(invoice.isGst ? 'TAX INVOICE (GST)' : 'BILL OF SUPPLY (NON-GST)', 40, 110);
      doc.fontSize(10).text(`Invoice No: ${invoiceNumber}`, 40, 130);
      doc.text(`Date      : ${new Date().toLocaleDateString('en-IN')}`, 40, 144);
      doc.text(`Due Date  : ${invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString('en-IN') : 'Immediate'}`, 40, 158);

      // Customer Details (Right Aligned)
      doc.text('BILLED TO:', 350, 110);
      doc.font('Helvetica-Bold').text(customer.name, 350, 124);
      doc.font('Helvetica').text(customer.companyName || '', 350, 138);
      doc.text(`Phone: ${customer.phone}`, 350, 152);
      if (customer.gstNumber) doc.text(`GSTIN: ${customer.gstNumber}`, 350, 166);

      // Table Header
      const tableTop = 190;
      doc.rect(40, tableTop, 515, 20).fill('#002B49');
      doc.fillColor('#FFFFFF').fontSize(9);
      doc.text('DESCRIPTION', 45, tableTop + 6);
      doc.text('SQ.FT', 320, tableTop + 6);
      doc.text('RATE (₹)', 390, tableTop + 6);
      doc.text('AMOUNT (₹)', 480, tableTop + 6);

      let currentY = tableTop + 24;
      doc.fillColor('#111827');
      for (const item of items) {
        doc.text(item.itemDescription, 45, currentY, { width: 260 });
        doc.text(item.totalSqFt.toString(), 320, currentY);
        doc.text(`₹${item.unitRate}`, 390, currentY);
        doc.text(`₹${item.amount.toLocaleString()}`, 480, currentY);
        currentY += 22;
      }

      currentY = Math.max(currentY + 10, 360);
      doc.moveTo(320, currentY).lineTo(555, currentY).strokeColor('#E2E8F0').lineWidth(1).stroke();
      currentY += 8;

      const summaryLines = [
        ['Subtotal Amount', `Rs. ${invoice.subtotalAmount.toLocaleString()}`],
        ['Framing Charges', `+ Rs. ${invoice.framingCharges.toLocaleString()}`],
        ['Installation Charges', `+ Rs. ${invoice.installationCharges.toLocaleString()}`],
        ['Discount', `- Rs. ${invoice.discountAmount.toLocaleString()}`],
        [`GST (${invoice.gstPercentage}%)`, `+ Rs. ${invoice.gstAmount.toLocaleString()}`],
        ['Total Invoice Amount', `Rs. ${invoice.totalAmount.toLocaleString()}`],
        ['Paid to Date', `- Rs. ${invoice.paidAmount.toLocaleString()}`],
      ];

      for (const [label, val] of summaryLines) {
        doc.fontSize(9).text(label, 330, currentY);
        doc.text(val, 460, currentY, { align: 'right' });
        currentY += 15;
      }

      doc.rect(320, currentY, 235, 24).fill('#002B49');
      doc.fillColor('#FFFFFF').fontSize(11).text('BALANCE DUE:', 330, currentY + 6);
      doc.fontSize(12).text(`Rs. ${invoice.pendingBalance.toLocaleString()}`, 450, currentY + 5, { align: 'right' });

      // Bank Details for Payment
      doc.fillColor('#111827').fontSize(10).text('Payment Information:', 40, currentY + 35);
      doc.fontSize(8).fillColor('#444444');
      doc.text('Bank Name: HDFC Bank Ltd | Account: 50200012345678', 40, currentY + 49);
      doc.text('IFSC: HDFC0000123 | UPI ID: apexsignage@hdfcbank', 40, currentY + 61);

      doc.end();
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });
  }
}
