import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { PaymentsService, RecordPaymentDto } from './payments.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Payments & Ledger')
@Controller('payments')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Get()
  @ApiOperation({ summary: 'List all payment transactions' })
  @ApiQuery({ name: 'invoiceId', required: false })
  async findAll(@Query('invoiceId') invoiceId?: string) {
    return this.paymentsService.findAll(invoiceId);
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Record payment transaction and auto-calculate remaining balance' })
  async recordPayment(@Body() dto: RecordPaymentDto, @CurrentUser('id') receivedById: string) {
    return this.paymentsService.recordPayment(dto, receivedById);
  }
}
