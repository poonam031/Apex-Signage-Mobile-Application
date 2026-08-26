import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { InventoryCategory, InventoryUnit, StockTransactionType, NotificationChannel, UserRole } from '@prisma/client';

export interface CreateInventoryItemDto {
  name: string;
  category: InventoryCategory;
  unit: InventoryUnit;
  currentStock: number;
  minStockAlert: number;
  costPrice?: number;
  sellingPrice?: number;
  supplierName?: string;
}

export interface RecordStockTransactionDto {
  inventoryItemId: string;
  type: StockTransactionType;
  quantity: number;
  referenceJobId?: string;
  reason?: string;
}

@Injectable()
export class InventoryService {
  constructor(
    private prisma: PrismaService,
    private notificationsService: NotificationsService,
  ) {}

  async findAll(category?: InventoryCategory, isLowStock?: boolean) {
    const items = await this.prisma.inventoryItem.findMany({
      where: {
        ...(category ? { category } : {}),
      },
      include: {
        _count: { select: { transactions: true } },
      },
      orderBy: { name: 'asc' },
    });

    if (isLowStock) {
      return items.filter((i) => i.currentStock <= i.minStockAlert);
    }

    return items;
  }

  async findOne(id: string) {
    const item = await this.prisma.inventoryItem.findUnique({
      where: { id },
      include: {
        transactions: {
          orderBy: { createdAt: 'desc' },
          take: 30,
          include: {
            performedBy: { select: { id: true, name: true } },
            referenceJob: { select: { id: true, jobCode: true } },
          },
        },
      },
    });
    if (!item) throw new NotFoundException('Inventory item not found');
    return item;
  }

  async create(dto: CreateInventoryItemDto) {
    return this.prisma.inventoryItem.create({ data: dto });
  }

  async update(id: string, data: any) {
    return this.prisma.inventoryItem.update({ where: { id }, data });
  }

  async recordTransaction(dto: RecordStockTransactionDto, performedById: string) {
    const item = await this.prisma.inventoryItem.findUnique({ where: { id: dto.inventoryItemId } });
    if (!item) throw new NotFoundException('Inventory item not found');

    let newStock = item.currentStock;
    if (dto.type === StockTransactionType.STOCK_IN) {
      newStock += dto.quantity;
    } else if (dto.type === StockTransactionType.STOCK_OUT || dto.type === StockTransactionType.WASTE) {
      if (item.currentStock < dto.quantity) {
        throw new BadRequestException(`Insufficient stock. Current: ${item.currentStock} ${item.unit}`);
      }
      newStock -= dto.quantity;
    } else if (dto.type === StockTransactionType.ADJUSTMENT) {
      newStock = dto.quantity;
    }

    // Save transaction and update item in single atomic transaction
    const [transaction, updatedItem] = await this.prisma.$transaction([
      this.prisma.stockTransaction.create({
        data: {
          inventoryItemId: dto.inventoryItemId,
          type: dto.type,
          quantity: dto.quantity,
          referenceJobId: dto.referenceJobId,
          performedById,
          reason: dto.reason,
        },
        include: {
          inventoryItem: true,
          performedBy: { select: { id: true, name: true } },
        },
      }),
      this.prisma.inventoryItem.update({
        where: { id: dto.inventoryItemId },
        data: { currentStock: newStock },
      }),
    ]);

    // Check Low-Stock Alert
    if (updatedItem.currentStock <= updatedItem.minStockAlert) {
      const superAdmins = await this.prisma.user.findMany({
        where: { role: UserRole.SUPER_ADMIN, isActive: true },
      });

      for (const admin of superAdmins) {
        await this.notificationsService.dispatch({
          userId: admin.id,
          title: `⚠️ Low Stock Alert: ${updatedItem.name}`,
          message: `Stock level for "${updatedItem.name}" has fallen to ${updatedItem.currentStock} ${updatedItem.unit} (Minimum threshold: ${updatedItem.minStockAlert} ${updatedItem.unit}).`,
          channels: [NotificationChannel.IN_APP, NotificationChannel.WHATSAPP],
          dataPayload: { inventoryItemId: updatedItem.id },
        });
      }
    }

    return {
      message: 'Stock movement recorded successfully',
      transaction,
      updatedStock: updatedItem.currentStock,
    };
  }

  async getLowStockSummary() {
    const items = await this.prisma.inventoryItem.findMany();
    const lowStockItems = items.filter((i) => i.currentStock <= i.minStockAlert);
    return {
      totalItems: items.length,
      lowStockCount: lowStockItems.length,
      lowStockItems,
    };
  }
}
