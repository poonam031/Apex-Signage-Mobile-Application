import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PettyCashService, CreatePettyCashDto } from './petty-cash.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ExpenseStatus, UserRole } from '@prisma/client';

@ApiTags('Daily Petty Cash')
@Controller('petty-cash')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class PettyCashController {
  constructor(private pettyCashService: PettyCashService) {}

  @Get()
  @ApiOperation({ summary: 'List petty cash expenses (filter by status, employee or job)' })
  @ApiQuery({ name: 'status', enum: ExpenseStatus, required: false })
  @ApiQuery({ name: 'employeeId', required: false })
  @ApiQuery({ name: 'jobId', required: false })
  async findAll(
    @CurrentUser('id') currentUserId: string,
    @CurrentUser('role') role: UserRole,
    @Query('status') status?: ExpenseStatus,
    @Query('employeeId') employeeId?: string,
    @Query('jobId') jobId?: string,
  ) {
    const targetEmployee = role === UserRole.SUPER_ADMIN ? employeeId : currentUserId;
    return this.pettyCashService.findAll(status, targetEmployee, jobId);
  }

  @Get('summary')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Get total petty cash expenses overview (Super Admin)' })
  async getSummary() {
    return this.pettyCashService.getSummary();
  }

  @Post()
  @ApiOperation({ summary: 'Submit site petty cash expense (screws, adhesive, tempo rental, tea)' })
  async create(@Body() dto: CreatePettyCashDto, @CurrentUser('id') employeeId: string) {
    return this.pettyCashService.create(dto, employeeId);
  }

  @Put(':id/status')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Approve or Reject petty cash expense (Super Admin)' })
  async updateStatus(
    @Param('id') id: string,
    @Body('status') status: ExpenseStatus,
    @CurrentUser('id') approvedById: string,
  ) {
    return this.pettyCashService.updateStatus(id, status, approvedById);
  }
}
