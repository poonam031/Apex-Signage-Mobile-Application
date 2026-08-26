import { Controller, Get, Put, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SettingsService } from './settings.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Business Settings & Configuration')
@Controller('settings')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class SettingsController {
  constructor(private settingsService: SettingsService) {}

  @Get()
  @ApiOperation({ summary: 'Get all configurable business settings' })
  async findAll() {
    return this.settingsService.findAll();
  }

  @Get(':key')
  @ApiOperation({ summary: 'Get specific configuration setting by key' })
  async findByKey(@Param('key') key: string) {
    return this.settingsService.findByKey(key);
  }

  @Put(':key')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update business configuration setting (Super Admin)' })
  async update(
    @Param('key') key: string,
    @Body('value') value: string,
    @Body('description') description?: string,
  ) {
    return this.settingsService.update(key, value, description);
  }
}
