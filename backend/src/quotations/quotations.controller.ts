import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { QuotationsService, CreateQuotationDto } from './quotations.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Quotations & Estimates')
@Controller('quotations')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class QuotationsController {
  constructor(private quotationsService: QuotationsService) {}

  @Get()
  @ApiOperation({ summary: 'List all quotations' })
  async findAll() {
    return this.quotationsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single quotation with line items and PDF' })
  async findOne(@Param('id') id: string) {
    return this.quotationsService.findOne(id);
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Create new quotation with automatic rate calculation & branded PDF' })
  async create(@Body() dto: CreateQuotationDto) {
    return this.quotationsService.create(dto);
  }

  @Post(':id/send-whatsapp')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Send generated Quotation PDF directly to customer WhatsApp' })
  async sendViaWhatsApp(@Param('id') id: string) {
    return this.quotationsService.sendViaWhatsApp(id);
  }
}
