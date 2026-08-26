import { Controller, Get, Post, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { InvoicesService, CreateInvoiceFromQuotationDto } from './invoices.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { InvoiceStatus, UserRole } from '@prisma/client';

@ApiTags('Invoices & Billing')
@Controller('invoices')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class InvoicesController {
  constructor(private invoicesService: InvoicesService) {}

  @Get()
  @ApiOperation({ summary: 'List all invoices with status & customer filter' })
  @ApiQuery({ name: 'status', enum: InvoiceStatus, required: false })
  @ApiQuery({ name: 'customerId', required: false })
  async findAll(@Query('status') status?: InvoiceStatus, @Query('customerId') customerId?: string) {
    return this.invoicesService.findAll(status, customerId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single invoice with payments, balance & PDF url' })
  async findOne(@Param('id') id: string) {
    return this.invoicesService.findOne(id);
  }

  @Post('from-quotation')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Convert approved quotation into GST / Non-GST Invoice' })
  async createFromQuotation(@Body() dto: CreateInvoiceFromQuotationDto) {
    return this.invoicesService.createFromQuotation(dto);
  }

  @Post(':id/send-whatsapp')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Send Invoice PDF document directly to customer via WhatsApp' })
  async sendInvoiceWhatsApp(@Param('id') id: string) {
    return this.invoicesService.sendInvoiceWhatsApp(id);
  }

  @Post(':id/send-reminder')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Send automatic payment reminder for outstanding balance' })
  async sendPaymentReminder(@Param('id') id: string) {
    return this.invoicesService.sendPaymentReminder(id);
  }
}
