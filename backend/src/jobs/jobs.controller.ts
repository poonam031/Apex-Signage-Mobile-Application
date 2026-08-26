import { Controller, Get, Post, Put, Body, Param, Query, UseGuards, Res } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JobsService, CreateJobDto } from './jobs.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JobStage, JobStatus, UserRole } from '@prisma/client';

@ApiTags('Digital Job Cards')
@Controller('jobs')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class JobsController {
  constructor(private jobsService: JobsService) {}

  @Get()
  @ApiOperation({ summary: 'List all digital job cards with filtering' })
  @ApiQuery({ name: 'stage', enum: JobStage, required: false })
  @ApiQuery({ name: 'status', enum: JobStatus, required: false })
  @ApiQuery({ name: 'search', required: false })
  async findAll(
    @Query('stage') stage?: JobStage,
    @Query('status') status?: JobStatus,
    @Query('search') search?: string,
  ) {
    return this.jobsService.findAll(stage, status, search);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get complete job card details, history & attachments' })
  async findOne(@Param('id') id: string) {
    return this.jobsService.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Create new digital job card (Super Admin / Office)' })
  async create(@Body() dto: CreateJobDto, @CurrentUser('id') creatorId: string) {
    return this.jobsService.create(dto, creatorId);
  }

  @Get('qr-scan/:qrToken')
  @ApiOperation({ summary: 'Instant scanner lookup: Get job details from scanned QR code' })
  async findByQr(@Param('qrToken') qrToken: string) {
    return this.jobsService.findByQrToken(qrToken);
  }

  @Post('qr-update-stage')
  @ApiOperation({ summary: '1-Second QR Stage Updater: Advance job stage instantly via QR code scan' })
  async updateStageViaQr(
    @Body()
    body: {
      qrCodeToken: string;
      targetStage: JobStage;
      remarks?: string;
      lat?: number;
      lng?: number;
    },
    @CurrentUser() user: { id: string; role: UserRole; name: string },
  ) {
    return this.jobsService.updateStageViaQr(
      body.qrCodeToken,
      body.targetStage,
      user,
      body.remarks,
      body.lat,
      body.lng,
    );
  }

  @Get(':id/qr-code')
  @ApiOperation({ summary: 'Generate printable QR code data URL for job card' })
  async getQrCode(@Param('id') id: string) {
    const job = await this.jobsService.findOne(id);
    const dataUrl = await this.jobsService.getQrCodeDataUrl(job.qrCodeToken);
    return {
      jobId: job.id,
      jobCode: job.jobCode,
      qrCodeToken: job.qrCodeToken,
      qrDataUrl: dataUrl,
    };
  }
}
