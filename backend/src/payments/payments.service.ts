import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import { PaymentMethod, InvoiceStatus } from '@prisma/client';

export interface RecordPaymentDto {
  invoiceId: string;
  amountPaid: number;
  paymentMethod: PaymentMethod;
  referenceNumber?: string;
  notes?: string;
}

@Injectable()
export class PaymentsService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
  ) {}

  async findAll(invoiceId?: string) {
    return this.prisma.payment.findMany({
      where: {
        ...(invoiceId ? { invoiceId } : {}),
      },
      include: {
        invoice: { select: { id: true, invoiceNumber: true, totalAmount: true } },
        customer: { select: { id: true, name: true, phone: true } },
        receivedBy: { select: { id: true, name: true } },
      },
      orderBy: { paymentDate: 'desc' },
    });
  }

  async recordPayment(dto: RecordPaymentDto, receivedById: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id: dto.invoiceId },
      include: { customer: true, payments: true },
    });
    if (!invoice) throw new NotFoundException('Invoice not found');

    const totalPaidBefore = invoice.payments.reduce((sum, p) => sum + p.amountPaid, 0);
    const newTotalPaid = totalPaidBefore + dto.amountPaid;
    const pendingBalance = this.calculationService.calculatePendingBalance(invoice.totalAmount, newTotalPaid);

    let newStatus: InvoiceStatus = InvoiceStatus.PARTIALLY_PAID;
    if (pendingBalance === 0) {
      newStatus = InvoiceStatus.FULLY_PAID;
    } else if (newTotalPaid === 0) {
      newStatus = InvoiceStatus.UNPAID;
    }

    const [payment] = await this.prisma.$transaction([
      this.prisma.payment.create({
        data: {
          invoiceId: dto.invoiceId,
          customerId: invoice.customerId,
          amountPaid: dto.amountPaid,
          paymentMethod: dto.paymentMethod,
          referenceNumber: dto.referenceNumber,
          receivedById,
          notes: dto.notes,
        },
        include: {
          invoice: true,
          customer: true,
          receivedBy: { select: { id: true, name: true } },
        },
      }),
      this.prisma.invoice.update({
        where: { id: dto.invoiceId },
        data: {
          paidAmount: newTotalPaid,
          pendingBalance,
          status: newStatus,
        },
      }),
    ]);

    // Also update Job Card pendingAmount if associated
    if (invoice.jobId) {
      await this.prisma.jobCard.update({
        where: { id: invoice.jobId },
        data: { pendingAmount: pendingBalance },
      });
    }

    return {
      message: 'Payment recorded successfully',
      payment,
      updatedInvoice: {
        totalAmount: invoice.totalAmount,
        paidAmount: newTotalPaid,
        pendingBalance,
        status: newStatus,
      },
    };
  }
}
