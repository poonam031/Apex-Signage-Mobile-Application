import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { SalaryService, GenerateSalarySlipDto } from './salary.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Salary & Payroll')
@Controller('salary')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class SalaryController {
  constructor(private salaryService: SalaryService) {}

  @Get('slips')
  @ApiOperation({ summary: 'List salary slips (filtered by user or month)' })
  @ApiQuery({ name: 'userId', required: false })
  @ApiQuery({ name: 'monthYear', required: false, example: '2026-08' })
  async getSlips(
    @CurrentUser('id') currentUserId: string,
    @CurrentUser('role') role: UserRole,
    @Query('userId') targetUserId?: string,
    @Query('monthYear') monthYear?: string,
  ) {
    const queryUser = role === UserRole.SUPER_ADMIN ? targetUserId : currentUserId;
    return this.salaryService.getSlips(queryUser, monthYear);
  }

  @Post('generate-slip')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Calculate monthly salary and generate branded PDF payslip (Super Admin)' })
  async generateSlip(@Body() dto: GenerateSalarySlipDto) {
    return this.salaryService.calculateAndGenerateSlip(dto);
  }
}
