import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RewardCategory } from '@prisma/client';

export interface AddRewardPointsDto {
  userId: string;
  points: number;
  category: RewardCategory;
  remarks?: string;
  referenceId?: string;
}

@Injectable()
export class RewardsService {
  constructor(private prisma: PrismaService) {}

  async addPoints(dto: AddRewardPointsDto) {
    const user = await this.prisma.user.findUnique({ where: { id: dto.userId } });
    if (!user) throw new NotFoundException('User not found');

    const reward = await this.prisma.rewardPoint.create({
      data: {
        userId: dto.userId,
        points: dto.points,
        category: dto.category,
        remarks: dto.remarks,
        referenceId: dto.referenceId,
      },
    });

    // Recalculate current month leaderboard
    const now = new Date();
    const monthYear = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    await this.updateMonthlyLeaderboard(monthYear);

    return reward;
  }

  async getUserPoints(userId: string) {
    const points = await this.prisma.rewardPoint.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
    const totalPoints = points.reduce((sum, p) => sum + p.points, 0);
    return { totalPoints, history: points };
  }

  async getLeaderboard(monthYear?: string) {
    const currentMonthYear =
      monthYear ||
      `${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`;

    await this.updateMonthlyLeaderboard(currentMonthYear);

    return this.prisma.leaderboardMonth.findMany({
      where: { monthYear: currentMonthYear },
      include: {
        user: { select: { id: true, name: true, role: true, avatarUrl: true } },
      },
      orderBy: { rank: 'asc' },
    });
  }

  async setEmployeeOfMonth(userId: string, monthYear: string, rewardAmount: number = 3000) {
    // Reset any existing employee of the month for that month
    await this.prisma.leaderboardMonth.updateMany({
      where: { monthYear },
      data: { isEmployeeOfMonth: false, rewardBonusAmount: 0 },
    });

    return this.prisma.leaderboardMonth.upsert({
      where: {
        userId_monthYear: { userId, monthYear },
      },
      create: {
        userId,
        monthYear,
        isEmployeeOfMonth: true,
        rewardBonusAmount: rewardAmount,
      },
      update: {
        isEmployeeOfMonth: true,
        rewardBonusAmount: rewardAmount,
      },
      include: { user: true },
    });
  }

  private async updateMonthlyLeaderboard(monthYear: string) {
    const [year, month] = monthYear.split('-').map(Number);
    const startOfMonth = new Date(year, month - 1, 1);
    const endOfMonth = new Date(year, month, 0, 23, 59, 59);

    const users = await this.prisma.user.findMany({ where: { isActive: true } });

    const userStats = await Promise.all(
      users.map(async (u) => {
        const points = await this.prisma.rewardPoint.findMany({
          where: {
            userId: u.id,
            createdAt: { gte: startOfMonth, lte: endOfMonth },
          },
        });
        const totalPoints = points.reduce((sum, p) => sum + p.points, 0);

        const dprs = await this.prisma.dailyProductionReport.findMany({
          where: {
            operatorId: u.id,
            date: { gte: startOfMonth, lte: endOfMonth },
          },
        });
        const totalSqFt = dprs.reduce((sum, d) => sum + d.printedSqFt, 0);

        return {
          userId: u.id,
          totalPoints,
          totalProductionSqFt: totalSqFt,
        };
      }),
    );

    // Sort by points descending
    userStats.sort((a, b) => b.totalPoints - a.totalPoints);

    for (let i = 0; i < userStats.length; i++) {
      const stat = userStats[i];
      const rank = i + 1;
      const isTop = rank === 1 && stat.totalPoints > 0;

      await this.prisma.leaderboardMonth.upsert({
        where: {
          userId_monthYear: {
            userId: stat.userId,
            monthYear,
          },
        },
        create: {
          userId: stat.userId,
          monthYear,
          totalPoints: stat.totalPoints,
          rank,
          totalProductionSqFt: stat.totalProductionSqFt,
          isEmployeeOfMonth: isTop,
          rewardBonusAmount: isTop ? 3000 : 0,
        },
        update: {
          totalPoints: stat.totalPoints,
          rank,
          totalProductionSqFt: stat.totalProductionSqFt,
          isEmployeeOfMonth: isTop,
          rewardBonusAmount: isTop ? 3000 : 0,
        },
      });
    }
  }
}
