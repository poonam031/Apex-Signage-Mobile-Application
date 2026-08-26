import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AuditService {
  constructor(private prisma: PrismaService) {}

  async findAll(limit: number = 100) {
    return this.prisma.auditLog.findMany({
      include: {
        user: { select: { id: true, name: true, role: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async logAction(userId: string | null, action: string, entity: string, entityId: string, payload?: any, ip?: string, userAgent?: string) {
    return this.prisma.auditLog.create({
      data: {
        userId,
        action,
        entity,
        entityId,
        ipAddress: ip,
        userAgent,
        changesPayload: payload ? JSON.stringify(payload) : null,
      },
    });
  }
}
