import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { CustomersService } from './customers.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';

@ApiTags('Customers CRM')
@Controller('customers')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CustomersController {
  constructor(private customersService: CustomersService) {}

  @Get()
  @ApiOperation({ summary: 'List all customers with search support' })
  @ApiQuery({ name: 'search', required: false, description: 'Search by name, company, or phone' })
  async findAll(@Query('search') search?: string) {
    return this.customersService.findAll(search);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single customer profile with full job and invoice history' })
  async findOne(@Param('id') id: string) {
    return this.customersService.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create new customer' })
  async create(@Body() body: any) {
    return this.customersService.create(body);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update customer details' })
  async update(@Param('id') id: string, @Body() body: any) {
    return this.customersService.update(id, body);
  }
}
