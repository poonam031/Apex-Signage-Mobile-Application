import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RewardCategory } from '@prisma/client';

export interface CreateDprDto {
  date?: string | Date;
  operatorId: string;
  machineId: string;
  jobId?: string;
  printedSqFt: number;
  materialUsed: string;
  wasteSqFt?: number;
  remarks?: string;
}

@Injectable()
export class DprService {
  constructor(private prisma: PrismaService) {}

  async findAll(dateFrom?: string, dateTo?: string, operatorId?: string, machineId?: string) {
    const where: any = {};
    if (dateFrom || dateTo) {
      where.date = {
        ...(dateFrom ? { gte: new Date(dateFrom) } : {}),
        ...(dateTo ? { lte: new Date(dateTo) } : {}),
      };
    }
    if (operatorId) where.operatorId = operatorId;
    if (machineId) where.machineId = machineId;

    return this.prisma.dailyProductionReport.findMany({
      where,
      include: {
        operator: { select: { id: true, name: true, phone: true } },
        machine: true,
        job: { select: { id: true, jobCode: true, boardType: true, customer: { select: { name: true } } } },
      },
      orderBy: { date: 'desc' },
    });
  }

  async create(dto: CreateDprDto) {
    const operator = await this.prisma.user.findUnique({ where: { id: dto.operatorId } });
    if (!operator) throw new NotFoundException('Operator not found');

    const machine = await this.prisma.machine.findUnique({ where: { id: dto.machineId } });
    if (!machine) throw new NotFoundException('Machine not found');

    const waste = dto.wasteSqFt || 0;
    const dpr = await this.prisma.dailyProductionReport.create({
      data: {
        date: dto.date ? new Date(dto.date) : new Date(),
        operatorId: dto.operatorId,
        machineId: dto.machineId,
        jobId: dto.jobId,
        printedSqFt: dto.printedSqFt,
        materialUsed: dto.materialUsed,
        wasteSqFt: waste,
        remarks: dto.remarks,
      },
      include: {
        operator: { select: { id: true, name: true } },
        machine: true,
      },
    });

    // Gamification Points Rules:
    // 1. 50 points for every 100 Sq.Ft printed
    const productionPoints = Math.floor(dto.printedSqFt / 100) * 50;
    if (productionPoints > 0) {
      await this.prisma.rewardPoint.create({
        data: {
          userId: dto.operatorId,
          points: productionPoints,
          category: RewardCategory.PRODUCTION_100SQFT,
          referenceId: dpr.id,
          remarks: `Earned ${productionPoints} points for printing ${dto.printedSqFt} Sq.Ft on ${machine.name}`,
        },
      });
    }

    // 2. 100 bonus points for zero / very low waste run (< 2% waste)
    if (dto.printedSqFt >= 50 && waste <= (dto.printedSqFt * 0.02)) {
      await this.prisma.rewardPoint.create({
        data: {
          userId: dto.operatorId,
          points: 100,
          category: RewardCategory.ZERO_WASTE,
          referenceId: dpr.id,
          remarks: `Zero-waste bonus points for high efficiency printing on ${machine.name}`,
        },
      });
    }

    return dpr;
  }

  async getProductionStats() {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const reportsToday = await this.prisma.dailyProductionReport.findMany({
      where: { date: { gte: today } },
      include: { machine: true, operator: true },
    });

    const totalSqFtToday = reportsToday.reduce((sum, r) => sum + r.printedSqFt, 0);
    const totalWasteToday = reportsToday.reduce((sum, r) => sum + r.wasteSqFt, 0);

    const allReports = await this.prisma.dailyProductionReport.findMany({
      include: { machine: true, operator: true },
    });

    const machineStats: Record<string, { name: string; type: string; totalSqFt: number; wasteSqFt: number }> = {};
    for (const r of allReports) {
      if (!machineStats[r.machineId]) {
        machineStats[r.machineId] = {
          name: r.machine.name,
          type: r.machine.type,
          totalSqFt: 0,
          wasteSqFt: 0,
        };
      }
      machineStats[r.machineId].totalSqFt += r.printedSqFt;
      machineStats[r.machineId].wasteSqFt += r.wasteSqFt;
    }

    return {
      today: {
        totalPrintedSqFt: totalSqFtToday,
        totalWasteSqFt: totalWasteToday,
        wastePercentage: totalSqFtToday > 0 ? Math.round((totalWasteToday / totalSqFtToday) * 1000) / 10 : 0,
        reportsCount: reportsToday.length,
      },
      machines: Object.values(machineStats),
    };
  }
}
