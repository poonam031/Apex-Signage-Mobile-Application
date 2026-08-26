import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { DprService, CreateDprDto } from './dpr.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Daily Production Reports (DPR)')
@Controller('dpr')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class DprController {
  constructor(private dprService: DprService) {}

  @Get()
  @ApiOperation({ summary: 'List daily production reports with date & operator filters' })
  @ApiQuery({ name: 'dateFrom', required: false })
  @ApiQuery({ name: 'dateTo', required: false })
  @ApiQuery({ name: 'operatorId', required: false })
  @ApiQuery({ name: 'machineId', required: false })
  async findAll(
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
    @Query('operatorId') operatorId?: string,
    @Query('machineId') machineId?: string,
  ) {
    return this.dprService.findAll(dateFrom, dateTo, operatorId, machineId);
  }

  @Get('stats')
  @ApiOperation({ summary: 'Get overall production summary and machine efficiency metrics' })
  async getStats() {
    return this.dprService.getProductionStats();
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN, UserRole.DESIGNER_OPERATOR)
  @ApiOperation({ summary: 'Record daily production entry (auto-awards points to operator)' })
  async create(@Body() dto: CreateDprDto, @CurrentUser('id') currentUserId: string) {
    if (!dto.operatorId) dto.operatorId = currentUserId;
    return this.dprService.create(dto);
  }
}
