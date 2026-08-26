import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PettyCashCategory, ExpenseStatus, UserRole } from '@prisma/client';

export interface CreatePettyCashDto {
  jobId?: string;
  category: PettyCashCategory;
  amount: number;
  description: string;
  receiptPhotoUrl?: string;
}

@Injectable()
export class PettyCashService {
  constructor(private prisma: PrismaService) {}

  async findAll(status?: ExpenseStatus, employeeId?: string, jobId?: string) {
    return this.prisma.pettyCashExpense.findMany({
      where: {
        ...(status ? { status } : {}),
        ...(employeeId ? { employeeId } : {}),
        ...(jobId ? { jobId } : {}),
      },
      include: {
        employee: { select: { id: true, name: true, phone: true, role: true } },
        approvedBy: { select: { id: true, name: true } },
        job: { select: { id: true, jobCode: true, boardType: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(dto: CreatePettyCashDto, employeeId: string) {
    return this.prisma.pettyCashExpense.create({
      data: {
        jobId: dto.jobId,
        employeeId,
        category: dto.category,
        amount: dto.amount,
        description: dto.description,
        receiptPhotoUrl: dto.receiptPhotoUrl,
        status: ExpenseStatus.PENDING,
      },
      include: {
        employee: { select: { id: true, name: true } },
        job: true,
      },
    });
  }

  async updateStatus(id: string, status: ExpenseStatus, approvedById: string) {
    const expense = await this.prisma.pettyCashExpense.findUnique({ where: { id } });
    if (!expense) throw new NotFoundException('Expense record not found');

    return this.prisma.pettyCashExpense.update({
      where: { id },
      data: {
        status,
        approvedById: status === ExpenseStatus.APPROVED ? approvedById : null,
      },
      include: {
        employee: { select: { id: true, name: true } },
        approvedBy: { select: { id: true, name: true } },
      },
    });
  }

  async getSummary() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const allExpenses = await this.prisma.pettyCashExpense.findMany();
    const approvedExpenses = allExpenses.filter((e) => e.status === ExpenseStatus.APPROVED);
    const pendingExpenses = allExpenses.filter((e) => e.status === ExpenseStatus.PENDING);

    const totalApprovedAmount = approvedExpenses.reduce((sum, e) => sum + e.amount, 0);
    const totalPendingAmount = pendingExpenses.reduce((sum, e) => sum + e.amount, 0);

    return {
      totalApprovedAmount,
      totalPendingAmount,
      pendingCount: pendingExpenses.length,
      approvedCount: approvedExpenses.length,
    };
  }
}
