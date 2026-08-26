import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { ReportsService } from './reports.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Business Reports & Executive Dashboard')
@Controller('reports')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class ReportsController {
  constructor(private reportsService: ReportsService) {}

  @Get('dashboard')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Executive Super Admin Dashboard: P&L, Active Stage Breakdown, DPR, Attendance & Financials' })
  async getDashboard() {
    return this.reportsService.getExecutiveDashboardMetrics();
  }
}
