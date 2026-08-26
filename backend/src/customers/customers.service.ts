import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CustomersService {
  constructor(private prisma: PrismaService) {}

  async findAll(search?: string) {
    return this.prisma.customer.findMany({
      where: {
        deletedAt: null,
        ...(search
          ? {
              OR: [
                { name: { contains: search, mode: 'insensitive' } },
                { companyName: { contains: search, mode: 'insensitive' } },
                { phone: { contains: search } },
              ],
            }
          : {}),
      },
      include: {
        _count: {
          select: { jobs: true, siteVisits: true, invoices: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const customer = await this.prisma.customer.findUnique({
      where: { id },
      include: {
        siteVisits: { orderBy: { createdAt: 'desc' } },
        jobs: { orderBy: { createdAt: 'desc' } },
        quotations: { orderBy: { createdAt: 'desc' } },
        invoices: {
          orderBy: { createdAt: 'desc' },
          include: { payments: true },
        },
        feedbacks: true,
      },
    });
    if (!customer) throw new NotFoundException('Customer not found');
    return customer;
  }

  async create(data: {
    name: string;
    companyName?: string;
    phone: string;
    email?: string;
    address: string;
    gstNumber?: string;
    latitude?: number;
    longitude?: number;
    notes?: string;
  }) {
    return this.prisma.customer.create({
      data,
    });
  }

  async update(id: string, data: any) {
    return this.prisma.customer.update({
      where: { id },
      data,
    });
  }
}
