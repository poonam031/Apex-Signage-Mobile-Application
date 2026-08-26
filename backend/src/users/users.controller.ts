import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Users & Staff')
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private usersService: UsersService) {}

  @Get()
  @Roles(UserRole.SUPER_ADMIN, UserRole.DESIGNER_OPERATOR)
  @ApiOperation({ summary: 'List all staff members or filter by role' })
  @ApiQuery({ name: 'role', enum: UserRole, required: false })
  async findAll(@Query('role') role?: UserRole) {
    return this.usersService.findAll(role);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user details by ID' })
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Post()
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Create new staff member (Super Admin only)' })
  async create(@Body() body: any) {
    return this.usersService.create(body);
  }

  @Put(':id')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Update staff member information' })
  async update(@Param('id') id: string, @Body() body: any) {
    return this.usersService.update(id, body);
  }
}
