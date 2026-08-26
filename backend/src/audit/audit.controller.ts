import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AuditService } from './audit.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Audit Logs')
@Controller('audit')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class AuditController {
  constructor(private auditService: AuditService) {}

  @Get()
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'View audit logs for critical operations (Super Admin)' })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async findAll(@Query('limit') limit?: number) {
    return this.auditService.findAll(limit ? Number(limit) : 100);
  }
}
