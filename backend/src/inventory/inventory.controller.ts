import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { InventoryService, CreateInventoryItemDto, RecordStockTransactionDto } from './inventory.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { InventoryCategory, UserRole } from '@prisma/client';

@ApiTags('Inventory & Low-Stock Alerts')
@Controller('inventory')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class InventoryController {
  constructor(private inventoryService: InventoryService) {}

  @Get()
  @ApiOperation({ summary: 'List inventory materials (rolls, acrylic, LEDs, SMPS, pipes)' })
  @ApiQuery({ name: 'category', enum: InventoryCategory, required: false })
  @ApiQuery({ name: 'lowStock', type: Boolean, required: false })
  async findAll(@Query('category') category?: InventoryCategory, @Query('lowStock') lowStock?: string) {
    return this.inventoryService.findAll(category, lowStock === 'true');
  }

  @Get('low-stock-summary')
  @ApiOperation({ summary: 'Get quick low-stock alert dashboard summary' })
  async getLowStockSummary() {
    return this.inventoryService.getLowStockSummary();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single inventory item with transaction history' })
  async findOne(@Param('id') id: string) {
    return this.inventoryService.findOne(id);
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Add new material or inventory product' })
  async create(@Body() dto: CreateInventoryItemDto) {
    return this.inventoryService.create(dto);
  }

  @Put(':id')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update item threshold or supplier details' })
  async update(@Param('id') id: string, @Body() body: any) {
    return this.inventoryService.update(id, body);
  }

  @Post('transaction')
  @Roles(UserRole.SUPER_ADMIN, UserRole.DESIGNER_OPERATOR)
  @ApiOperation({ summary: 'Record stock-in, stock-out, waste or adjustment' })
  async recordTransaction(
    @Body() dto: RecordStockTransactionDto,
    @CurrentUser('id') performedById: string,
  ) {
    return this.inventoryService.recordTransaction(dto, performedById);
  }
}
