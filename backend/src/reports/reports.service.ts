import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { JobStage, JobStatus, ExpenseStatus } from '@prisma/client';

@Injectable()
export class ReportsService {
  constructor(private prisma: PrismaService) {}

  async getExecutiveDashboardMetrics() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // 1. Jobs by Stage
    const activeJobs = await this.prisma.jobCard.findMany({
      where: { status: JobStatus.ACTIVE },
      select: { currentStage: true, totalSqFt: true, totalAmount: true },
    });

    const stageBreakdown: Record<string, number> = {
      [JobStage.SITE_VISIT]: 0,
      [JobStage.DESIGN_FINAL]: 0,
      [JobStage.PRINTING]: 0,
      [JobStage.FABRICATION]: 0,
      [JobStage.INSTALLATION]: 0,
      [JobStage.DELIVERED]: 0,
    };

    let totalActiveSqFt = 0;
    for (const j of activeJobs) {
      stageBreakdown[j.currentStage] = (stageBreakdown[j.currentStage] || 0) + 1;
      totalActiveSqFt += j.totalSqFt;
    }

    // 2. Today's Site Visits
    const visitsToday = await this.prisma.siteVisit.findMany({
      where: { visitDateTime: { gte: today } },
    });

    // 3. Today's Production & Waste
    const dprsToday = await this.prisma.dailyProductionReport.findMany({
      where: { date: { gte: today } },
    });
    const printedSqFtToday = dprsToday.reduce((sum, d) => sum + d.printedSqFt, 0);
    const wasteSqFtToday = dprsToday.reduce((sum, d) => sum + d.wasteSqFt, 0);

    // 4. Low Stock Alerts
    const inventoryItems = await this.prisma.inventoryItem.findMany();
    const lowStockAlerts = inventoryItems.filter((i) => i.currentStock <= i.minStockAlert);

    // 5. Financials (Invoices, Payments, Petty Cash)
    const invoices = await this.prisma.invoice.findMany({
      where: { status: { not: 'CANCELLED' } },
    });
    const totalBilledAmount = invoices.reduce((sum, i) => sum + i.totalAmount, 0);
    const totalCollectedAmount = invoices.reduce((sum, i) => sum + i.paidAmount, 0);
    const totalPendingBalance = invoices.reduce((sum, i) => sum + i.pendingBalance, 0);

    // Approved Expenses
    const approvedExpenses = await this.prisma.pettyCashExpense.findMany({
      where: { status: ExpenseStatus.APPROVED },
    });
    const totalApprovedPettyCash = approvedExpenses.reduce((sum, e) => sum + e.amount, 0);

    // Total Monthly Payroll Base
    const activeStaff = await this.prisma.user.findMany({ where: { isActive: true } });
    const monthlyPayrollBase = activeStaff.reduce((sum, u) => sum + u.baseSalary, 0);

    // Estimated Net P&L
    const estimatedNetProfit = totalBilledAmount - totalApprovedPettyCash - (monthlyPayrollBase / 2);

    // 6. Attendance Today
    const attendanceToday = await this.prisma.attendance.findMany({
      where: { date: { gte: today } },
    });
    const presentCount = attendanceToday.filter((a) => a.status === 'PRESENT' || a.status === 'LATE').length;
    const lateCount = attendanceToday.filter((a) => a.status === 'LATE').length;

    // 7. Customer Ratings
    const feedbacks = await this.prisma.customerFeedback.findMany();
    const totalRatings = feedbacks.length;
    const avgRating = totalRatings > 0 ? feedbacks.reduce((sum, f) => sum + f.starRating, 0) / totalRatings : 5.0;

    return {
      overview: {
        activeJobsCount: activeJobs.length,
        totalActiveSqFt,
        todayVisitsCount: visitsToday.length,
        printedSqFtToday,
        wasteSqFtToday,
        lowStockItemsCount: lowStockAlerts.length,
        averageCustomerRating: Math.round(avgRating * 10) / 10,
        staffPresentToday: presentCount,
        staffLateToday: lateCount,
        totalStaff: activeStaff.length,
      },
      stageBreakdown,
      financials: {
        totalBilledAmount,
        totalCollectedAmount,
        totalPendingBalance,
        totalApprovedPettyCash,
        monthlyPayrollBase,
        estimatedNetProfit: Math.round(estimatedNetProfit * 100) / 100,
      },
      lowStockAlerts: lowStockAlerts.map((i) => ({
        id: i.id,
        name: i.name,
        currentStock: i.currentStock,
        minStockAlert: i.minStockAlert,
        unit: i.unit,
      })),
    };
  }
}
