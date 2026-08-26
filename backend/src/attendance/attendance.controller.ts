import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AttendanceService, CheckInDto } from './attendance.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Smart Attendance')
@Controller('attendance')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class AttendanceController {
  constructor(private attendanceService: AttendanceService) {}

  @Post('check-in')
  @ApiOperation({ summary: 'Smart check-in (200m Geofence GPS verification, QR scan, or Selfie)' })
  async checkIn(@Body() dto: CheckInDto, @CurrentUser('id') userId: string) {
    return this.attendanceService.checkIn(userId, dto);
  }

  @Post('check-out')
  @ApiOperation({ summary: 'Daily punch out / check-out' })
  async checkOut(@CurrentUser('id') userId: string) {
    return this.attendanceService.checkOut(userId);
  }

  @Get('today-status')
  @ApiOperation({ summary: 'Get current user check-in status for today' })
  async getTodayStatus(@CurrentUser('id') userId: string) {
    return this.attendanceService.getTodayStatus(userId);
  }

  @Get('history')
  @ApiOperation({ summary: 'View attendance history' })
  @ApiQuery({ name: 'userId', required: false })
  @ApiQuery({ name: 'monthYear', required: false, example: '2026-08' })
  async getHistory(
    @CurrentUser('id') currentUserId: string,
    @CurrentUser('role') role: string,
    @Query('userId') targetUserId?: string,
    @Query('monthYear') monthYear?: string,
  ) {
    // Non-admins can only see their own history
    const queryUserId = role === 'SUPER_ADMIN' ? targetUserId : currentUserId;
    return this.attendanceService.getAttendanceHistory(queryUserId, monthYear);
  }
}
