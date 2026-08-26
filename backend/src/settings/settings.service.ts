import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SettingsService {
  constructor(private prisma: PrismaService) {}

  async findAll() {
    return this.prisma.appSetting.findMany({
      orderBy: { category: 'asc' },
    });
  }

  async findByKey(key: string) {
    const setting = await this.prisma.appSetting.findUnique({ where: { key } });
    if (!setting) throw new NotFoundException(`Setting '${key}' not found`);
    return setting;
  }

  async update(key: string, value: string, description?: string) {
    return this.prisma.appSetting.upsert({
      where: { key },
      create: { key, value, description },
      update: { value, description },
    });
  }
}
