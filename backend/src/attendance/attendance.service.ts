import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import { AttendanceStatus, AttendanceMethod, RewardCategory } from '@prisma/client';

export interface CheckInDto {
  method: AttendanceMethod;
  latitude?: number;
  longitude?: number;
  qrToken?: string;
  selfieUrl?: string;
  notes?: string;
}

@Injectable()
export class AttendanceService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
  ) {}

  async checkIn(userId: string, dto: CheckInDto) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const existing = await this.prisma.attendance.findUnique({
      where: {
        userId_date: {
          userId,
          date: today,
        },
      },
    });

    if (existing) {
      throw new BadRequestException('You have already checked in for today.');
    }

    // Geofencing verification if method is GEOFENCE_GPS or coordinates are supplied
    let isVerified = true;
    let geofenceDistance = 0;

    const geofenceSetting = await this.prisma.appSetting.findUnique({
      where: { key: 'GEOFENCE_CONFIG' },
    });

    const config = geofenceSetting
      ? JSON.parse(geofenceSetting.value)
      : {
          latitude: parseFloat(process.env.DEFAULT_SHOP_LATITUDE || '19.0760'),
          longitude: parseFloat(process.env.DEFAULT_SHOP_LONGITUDE || '72.8777'),
          radiusMeters: parseInt(process.env.DEFAULT_GEOFENCE_RADIUS_METERS || '200'),
        };

    if (dto.latitude && dto.longitude) {
      const geoCheck = this.calculationService.isWithinGeofence(
        dto.latitude,
        dto.longitude,
        config.latitude,
        config.longitude,
        config.radiusMeters,
      );
      isVerified = geoCheck.isWithin;
      geofenceDistance = geoCheck.distanceMeters;

      if (dto.method === AttendanceMethod.GEOFENCE_GPS && !geoCheck.isWithin) {
        throw new BadRequestException(
          `Geofence verification failed. You are ${Math.round(geofenceDistance)}m away (Allowed radius: ${config.radiusMeters}m).`,
        );
      }
    }

    const now = new Date();
    // Rule: Check-in after 9:30 AM is marked LATE
    const cutoffHour = 9;
    const cutoffMinute = 30;
    const isLate = now.getHours() > cutoffHour || (now.getHours() === cutoffHour && now.getMinutes() > cutoffMinute);
    const status = isLate ? AttendanceStatus.LATE : AttendanceStatus.PRESENT;

    const attendance = await this.prisma.attendance.create({
      data: {
        userId,
        date: today,
        checkInTime: now,
        status,
        method: dto.method,
        checkInLat: dto.latitude,
        checkInLng: dto.longitude,
        selfieUrl: dto.selfieUrl,
        isVerified,
        notes: dto.notes ? `${dto.notes} (Distance: ${Math.round(geofenceDistance)}m)` : `Distance: ${Math.round(geofenceDistance)}m`,
      },
      include: {
        user: { select: { id: true, name: true, role: true } },
      },
    });

    return {
      message: `Checked in successfully as ${status}`,
      attendance,
      isLate,
      distanceMeters: Math.round(geofenceDistance),
    };
  }

  async checkOut(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await this.prisma.attendance.findUnique({
      where: {
        userId_date: {
          userId,
          date: today,
        },
      },
    });

    if (!attendance) {
      throw new BadRequestException('No check-in record found for today.');
    }

    if (attendance.checkOutTime) {
      throw new BadRequestException('You have already checked out for today.');
    }

    return this.prisma.attendance.update({
      where: { id: attendance.id },
      data: { checkOutTime: new Date() },
    });
  }

  async getTodayStatus(userId: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const attendance = await this.prisma.attendance.findUnique({
      where: {
        userId_date: {
          userId,
          date: today,
        },
      },
    });

    return {
      isCheckedIn: !!attendance,
      isCheckedOut: !!attendance?.checkOutTime,
      attendance,
    };
  }

  async getAttendanceHistory(userId?: string, monthYear?: string) {
    const where: any = {};
    if (userId) where.userId = userId;

    if (monthYear) {
      const [year, month] = monthYear.split('-').map(Number);
      const startOfMonth = new Date(year, month - 1, 1);
      const endOfMonth = new Date(year, month, 0, 23, 59, 59);
      where.date = { gte: startOfMonth, lte: endOfMonth };
    }

    return this.prisma.attendance.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, role: true, phone: true } },
      },
      orderBy: { date: 'desc' },
    });
  }
}
