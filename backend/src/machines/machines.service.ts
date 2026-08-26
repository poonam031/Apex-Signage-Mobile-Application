import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MachineType } from '@prisma/client';

@Injectable()
export class MachinesService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.machine.findMany({
      include: {
        _count: { select: { productionReports: true } },
      },
      orderBy: { name: 'asc' },
    });
  }

  async findOne(id: string) {
    const machine = await this.prisma.machine.findUnique({
      where: { id },
      include: {
        productionReports: {
          orderBy: { date: 'desc' },
          take: 20,
          include: { operator: { select: { id: true, name: true } } },
        },
      },
    });
    if (!machine) throw new NotFoundException('Machine not found');
    return machine;
  }

  async create(data: { name: string; type: MachineType; model?: string; maxCapacitySqFtPerDay?: number; notes?: string }) {
    return this.prisma.machine.create({ data });
  }

  async update(id: string, data: any) {
    return this.prisma.machine.update({ where: { id }, data });
  }
}
