import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import * as PDFDocument from 'pdfkit';
import * as fs from 'fs';
import * as path from 'path';

export interface GenerateSalarySlipDto {
  userId: string;
  monthYear: string; // e.g. "2026-08"
  workingDays?: number;
  overtimeHours?: number;
  overtimeRatePerHour?: number;
  bonusAdjustment?: number;
  deductions?: number;
}

@Injectable()
export class SalaryService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
  ) {}

  async calculateAndGenerateSlip(dto: GenerateSalarySlipDto) {
    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new NotFoundException('Employee not found');

    const [year, month] = dto.monthYear.split('-').map(Number);
    const startOfMonth = new Date(year, month - 1, 1);
    const endOfMonth = new Date(year, month, 0, 23, 59, 59);

    // Fetch month's attendance
    const attendances = await this.prisma.attendance.findMany({
      where: {
        userId: dto.userId,
        date: { gte: startOfMonth, lte: endOfMonth },
      },
    });

    const presentDays = attendances.filter((a) => a.status === 'PRESENT' || a.status === 'LATE').length;
    const lateMarksCount = attendances.filter((a) => a.status === 'LATE').length;

    // Fetch month's leaderboard / reward bonus if any
    const leaderboard = await this.prisma.leaderboardMonth.findUnique({
      where: {
        userId_monthYear: {
          userId: dto.userId,
          monthYear: dto.monthYear,
        },
      },
    });

    const rewardBonus = (leaderboard?.rewardBonusAmount || 0) + (dto.bonusAdjustment || 0);
    const workingDays = dto.workingDays || 30;
    const overtimeHours = dto.overtimeHours || 0;
    const overtimeRate = dto.overtimeRatePerHour || 100;
    const deductions = dto.deductions || 0;

    const calcResult = this.calculationService.calculateMonthlySalary(
      user.baseSalary,
      workingDays,
      presentDays,
      lateMarksCount,
      overtimeHours,
      overtimeRate,
      rewardBonus,
      deductions,
    );

    // Generate PDF Slip
    const pdfFileName = `salary_slip_${user.name.replace(/\s+/g, '_')}_${dto.monthYear}.pdf`;
    const uploadDir = process.env.UPLOAD_DESTINATION || './uploads';
    if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });
    const pdfPath = path.join(uploadDir, pdfFileName);

    await this.createSalarySlipPdf(pdfPath, user, dto.monthYear, calcResult);

    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    const slipPdfUrl = `${appUrl}/uploads/${pdfFileName}`;

    const salarySlip = await this.prisma.salarySlip.upsert({
      where: {
        userId_monthYear: {
          userId: dto.userId,
          monthYear: dto.monthYear,
        },
      },
      create: {
        userId: dto.userId,
        monthYear: dto.monthYear,
        baseSalary: user.baseSalary,
        totalDays: workingDays,
        presentDays,
        lateMarks: lateMarksCount,
        overtimeHours,
        rewardBonus,
        deductions,
        netSalary: calcResult.netSalary,
        slipPdfUrl,
      },
      update: {
        baseSalary: user.baseSalary,
        totalDays: workingDays,
        presentDays,
        lateMarks: lateMarksCount,
        overtimeHours,
        rewardBonus,
        deductions,
        netSalary: calcResult.netSalary,
        slipPdfUrl,
      },
      include: {
        user: { select: { id: true, name: true, role: true, email: true, phone: true } },
      },
    });

    return {
      message: 'Monthly salary slip generated successfully',
      salarySlip,
      breakdown: calcResult,
    };
  }

  async getSlips(userId?: string, monthYear?: string) {
    const where: any = {};
    if (userId) where.userId = userId;
    if (monthYear) where.monthYear = monthYear;

    return this.prisma.salarySlip.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, role: true, phone: true, email: true } },
      },
      orderBy: { monthYear: 'desc' },
    });
  }

  private async createSalarySlipPdf(
    filePath: string,
    user: any,
    monthYear: string,
    calc: any,
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40, size: 'A4' });
      const writeStream = fs.createWriteStream(filePath);
      doc.pipe(writeStream);

      // Header
      doc.fillColor('#002B49').fontSize(20).text('APEX SIGNAGE & PRINTING SOLUTIONS', { align: 'center' });
      doc.fontSize(10).fillColor('#666666').text('Plot 42, Industrial Area Phase 2, Mumbai | contact@apexsignage.com', { align: 'center' });
      doc.moveDown(1);
      doc.fillColor('#111827').fontSize(14).text(`SALARY PAYSLIP - ${monthYear}`, { align: 'center', underline: true });
      doc.moveDown(1);

      // Employee Information Box
      doc.fontSize(10).fillColor('#111827');
      doc.text(`Employee Name : ${user.name}`);
      doc.text(`Designation   : ${user.role}`);
      doc.text(`Phone Number  : ${user.phone}`);
      doc.text(`Total Days    : ${calc.workingDays} | Present Days: ${calc.presentDays} | Late Marks: ${calc.lateMarksCount}`);
      doc.moveDown(1);

      // Table Breakdown
      doc.rect(40, doc.y, 515, 20).fill('#002B49');
      doc.fillColor('#FFFFFF').fontSize(10).text('EARNINGS & ALLOWANCES', 50, doc.y - 15);
      doc.text('AMOUNT (INR)', 430, doc.y);
      doc.moveDown(0.8);

      const items = [
        ['Basic Monthly Salary', `Rs. ${calc.baseSalary.toLocaleString()}`],
        [`Earned Base Pay (${calc.presentDays}/${calc.workingDays} Days)`, `Rs. ${calc.earnedBaseSalary.toLocaleString()}`],
        [`Overtime (${calc.overtimeHours} hrs)`, `+ Rs. ${calc.overtimeEarnings.toLocaleString()}`],
        ['Reward & Gamification Bonus', `+ Rs. ${calc.rewardBonus.toLocaleString()}`],
        ['Late Marks Penalty Deduction', `- Rs. ${calc.latePenalty.toLocaleString()}`],
        ['Other Deductions / Advances', `- Rs. ${calc.deductions.toLocaleString()}`],
      ];

      doc.fillColor('#111827');
      for (const [label, val] of items) {
        doc.text(label, 50, doc.y + 5);
        doc.text(val, 430, doc.y, { align: 'right' });
        doc.moveDown(0.5);
      }

      doc.moveDown(1);
      doc.rect(40, doc.y, 515, 25).fill('#E2E8F0');
      doc.fillColor('#002B49').fontSize(12).text('NET TAKE HOME PAY:', 50, doc.y - 18);
      doc.fontSize(14).text(`Rs. ${calc.netSalary.toLocaleString()}`, 400, doc.y - 18, { align: 'right' });

      doc.moveDown(3);
      doc.fontSize(9).fillColor('#666666').text('This is a computer-generated salary slip and does not require physical signature.', { align: 'center' });

      doc.end();
      writeStream.on('finish', resolve);
      writeStream.on('error', reject);
    });
  }
}
