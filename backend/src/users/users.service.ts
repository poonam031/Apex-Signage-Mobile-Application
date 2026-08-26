import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(role?: UserRole) {
    return this.prisma.user.findMany({
      where: {
        deletedAt: null,
        ...(role ? { role } : {}),
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        baseSalary: true,
        avatarUrl: true,
        createdAt: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  async findOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        baseSalary: true,
        avatarUrl: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async create(data: { name: string; email: string; phone: string; password?: string; role: UserRole; baseSalary?: number }) {
    const existing = await this.prisma.user.findFirst({
      where: {
        OR: [{ email: data.email.toLowerCase() }, { phone: data.phone }],
      },
    });
    if (existing) {
      throw new BadRequestException('User with this email or phone already exists');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(data.password || 'welcome123', salt);

    return this.prisma.user.create({
      data: {
        name: data.name,
        email: data.email.toLowerCase(),
        phone: data.phone,
        passwordHash,
        role: data.role,
        baseSalary: data.baseSalary || 18000,
      },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        baseSalary: true,
      },
    });
  }

  async update(id: string, data: { name?: string; phone?: string; isActive?: boolean; baseSalary?: number; avatarUrl?: string }) {
    return this.prisma.user.update({
      where: { id },
      data,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        baseSalary: true,
        avatarUrl: true,
      },
    });
  }
}
