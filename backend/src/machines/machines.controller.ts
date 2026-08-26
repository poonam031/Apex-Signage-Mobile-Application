import { Controller, Get, Post, Put, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { MachinesService } from './machines.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Machines')
@Controller('machines')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class MachinesController {
  constructor(private machinesService: MachinesService) {}

  @Get()
  @ApiOperation({ summary: 'List all printing machines and CNC routers' })
  async findAll() {
    return this.machinesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get machine profile and recent production records' })
  async findOne(@Param('id') id: string) {
    return this.machinesService.findOne(id);
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Add new machine to factory fleet' })
  async create(@Body() body: any) {
    return this.machinesService.create(body);
  }

  @Put(':id')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update machine specifications or status' })
  async update(@Param('id') id: string, @Body() body: any) {
    return this.machinesService.update(id, body);
  }
}
