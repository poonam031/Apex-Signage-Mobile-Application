import { Controller, Get, Post, Put, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { SiteVisitsService, CreateSiteVisitDto, SubmitSiteVisitDto } from './site-visits.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { SiteVisitStatus, UserRole } from '@prisma/client';

@ApiTags('Site Visits & Measurements')
@Controller('site-visits')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class SiteVisitsController {
  constructor(private siteVisitsService: SiteVisitsService) {}

  @Get()
  @ApiOperation({ summary: 'List site visits (filtered by role or status)' })
  @ApiQuery({ name: 'status', enum: SiteVisitStatus, required: false })
  async findAll(
    @CurrentUser('id') userId: string,
    @CurrentUser('role') userRole: UserRole,
    @Query('status') status?: SiteVisitStatus,
  ) {
    return this.siteVisitsService.findAll(userId, userRole, status);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single site visit with measurements, checklist & photos' })
  async findOne(@Param('id') id: string) {
    return this.siteVisitsService.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create & assign new site visit (Super Admin)' })
  async create(@Body() dto: CreateSiteVisitDto, @CurrentUser('id') creatorId: string) {
    return this.siteVisitsService.create(dto, creatorId);
  }

  @Put(':id/status')
  @ApiOperation({ summary: 'Update site visit workflow status' })
  async updateStatus(
    @Param('id') id: string,
    @Body('status') status: SiteVisitStatus,
    @CurrentUser('id') updatedById: string,
  ) {
    return this.siteVisitsService.updateStatus(id, status, updatedById);
  }

  @Post(':id/submit')
  @ApiOperation({ summary: 'Submit site measurements, technical checklist, annotated photos and 10s video' })
  async submitSiteVisit(
    @Param('id') id: string,
    @Body() dto: SubmitSiteVisitDto,
    @CurrentUser('id') submittedById: string,
  ) {
    return this.siteVisitsService.submitSiteVisit(id, dto, submittedById);
  }
}
