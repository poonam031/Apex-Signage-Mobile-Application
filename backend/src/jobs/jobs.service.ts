import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { JobStage, JobStatus, UserRole, NotificationChannel } from '@prisma/client';
import * as QRCode from 'qrcode';
import { v4 as uuidv4 } from 'uuid';

export interface CreateJobDto {
  customerId: string;
  siteVisitId?: string;
  boardType: string;
  deadline?: string | Date;
  assignedOperatorId?: string;
  assignedInstallerId?: string;
  notes?: string;
}

@Injectable()
export class JobsService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
    private notificationsService: NotificationsService,
  ) {}

  async findAll(stage?: JobStage, status?: JobStatus, search?: string) {
    return this.prisma.jobCard.findMany({
      where: {
        ...(stage ? { currentStage: stage } : {}),
        ...(status ? { status } : {}),
        ...(search
          ? {
              OR: [
                { jobCode: { contains: search, mode: 'insensitive' } },
                { boardType: { contains: search, mode: 'insensitive' } },
                { customer: { name: { contains: search, mode: 'insensitive' } } },
              ],
            }
          : {}),
      },
      include: {
        customer: true,
        assignedOperator: { select: { id: true, name: true, phone: true } },
        assignedInstaller: { select: { id: true, name: true, phone: true } },
        measurements: true,
        designFiles: { orderBy: { version: 'desc' }, take: 1 },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const job = await this.prisma.jobCard.findUnique({
      where: { id },
      include: {
        customer: true,
        siteVisit: {
          include: {
            measurements: true,
            technicalChecklist: true,
            siteMedias: true,
          },
        },
        assignedOperator: { select: { id: true, name: true, phone: true } },
        assignedInstaller: { select: { id: true, name: true, phone: true } },
        measurements: true,
        stageHistory: {
          include: { updatedBy: { select: { id: true, name: true, role: true } } },
          orderBy: { completedAt: 'asc' },
        },
        designFiles: { orderBy: { version: 'desc' } },
        productionReports: {
          include: { machine: true, operator: { select: { id: true, name: true } } },
        },
        quotations: true,
        invoices: { include: { payments: true } },
        pettyCashExpenses: { include: { employee: { select: { id: true, name: true } } } },
        feedbacks: true,
      },
    });
    if (!job) throw new NotFoundException('Job card not found');
    return job;
  }

  async create(dto: CreateJobDto, creatorId: string) {
    const customer = await this.prisma.customer.findUnique({ where: { id: dto.customerId } });
    if (!customer) throw new NotFoundException('Customer not found');

    // Generate Job Code: JB-YYYY-NNNN
    const year = new Date().getFullYear();
    const count = await this.prisma.jobCard.count();
    const jobCode = `JB-${year}-${String(count + 1).padStart(4, '0')}`;

    const qrCodeToken = uuidv4();
    const trackingToken = uuidv4();

    // Copy measurements from site visit if provided
    let totalSqFt = 0;
    if (dto.siteVisitId) {
      const visitMeasurements = await this.prisma.measurement.findMany({
        where: { siteVisitId: dto.siteVisitId },
      });
      totalSqFt = visitMeasurements.reduce((sum, m) => sum + m.squareFeet, 0);
    }

    const job = await this.prisma.jobCard.create({
      data: {
        jobCode,
        customerId: dto.customerId,
        siteVisitId: dto.siteVisitId,
        boardType: dto.boardType,
        currentStage: JobStage.SITE_VISIT,
        status: JobStatus.ACTIVE,
        deadline: dto.deadline ? new Date(dto.deadline) : null,
        assignedOperatorId: dto.assignedOperatorId,
        assignedInstallerId: dto.assignedInstallerId,
        qrCodeToken,
        trackingToken,
        totalSqFt,
        notes: dto.notes,
      },
      include: {
        customer: true,
        assignedOperator: true,
        assignedInstaller: true,
      },
    });

    // Record initial stage history
    await this.prisma.jobStageHistory.create({
      data: {
        jobId: job.id,
        stage: JobStage.SITE_VISIT,
        status: 'COMPLETED',
        updatedById: creatorId,
        remarks: 'Job card initialized from site visit data.',
      },
    });

    return job;
  }

  /**
   * Fast 1-Second QR Code Stage Scan & Stage Transition
   */
  async updateStageViaQr(
    qrCodeToken: string,
    targetStage: JobStage,
    user: { id: string; role: UserRole; name: string },
    remarks?: string,
    lat?: number,
    lng?: number,
  ) {
    const job = await this.prisma.jobCard.findUnique({
      where: { qrCodeToken },
      include: { customer: true, assignedInstaller: true },
    });

    if (!job) {
      throw new NotFoundException('Invalid QR code. Job card not found.');
    }

    // Role checks for stage transition
    if (user.role === UserRole.FIELD_BOY && targetStage !== JobStage.SITE_VISIT) {
      throw new ForbiddenException('Field staff cannot advance beyond site visit stage.');
    }
    if (user.role === UserRole.DESIGNER_OPERATOR && targetStage === JobStage.DELIVERED) {
      throw new ForbiddenException('Only Installation Team or Super Admin can mark as Delivered.');
    }

    const previousStage = job.currentStage;

    // Update job stage
    const updatedJob = await this.prisma.jobCard.update({
      where: { id: job.id },
      data: {
        currentStage: targetStage,
        status: targetStage === JobStage.DELIVERED ? JobStatus.COMPLETED : job.status,
      },
      include: { customer: true },
    });

    // Record Stage History
    await this.prisma.jobStageHistory.create({
      data: {
        jobId: job.id,
        stage: targetStage,
        status: 'COMPLETED',
        updatedById: user.id,
        remarks: remarks || `Stage advanced from ${previousStage} to ${targetStage} via QR scan by ${user.name}`,
        locationLat: lat,
        locationLng: lng,
      },
    });

    // Award reward points for timely milestones
    if (targetStage === JobStage.DELIVERED) {
      await this.prisma.rewardPoint.create({
        data: {
          userId: user.id,
          points: 80,
          category: 'TIMELY_INSTALLATION',
          referenceId: job.id,
          remarks: `Completed delivery & installation for ${job.jobCode}`,
        },
      });
    }

    // Customer Automatic Notifications
    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    const trackingUrl = `${appUrl}/tracking/${job.trackingToken}`;

    if (targetStage === JobStage.DESIGN_FINAL) {
      await this.notificationsService.dispatch({
        customerPhone: job.customer.phone,
        customerName: job.customer.name,
        title: '🎨 Design Proof Ready for Approval',
        message: `Your signage design for [${job.jobCode}] is ready for your review and approval.`,
        channels: [NotificationChannel.WHATSAPP, NotificationChannel.SMS],
        trackingUrl,
      });
    } else if (targetStage === JobStage.PRINTING) {
      await this.notificationsService.dispatch({
        customerPhone: job.customer.phone,
        customerName: job.customer.name,
        title: '🖨️ Production & Printing Started',
        message: `High-definition printing is currently in progress for your order [${job.jobCode}].`,
        channels: [NotificationChannel.WHATSAPP],
        trackingUrl,
      });
    } else if (targetStage === JobStage.INSTALLATION) {
      await this.notificationsService.dispatch({
        customerPhone: job.customer.phone,
        customerName: job.customer.name,
        title: '🚚 Installation Team Departed',
        message: `Our technical team has departed for site installation for [${job.jobCode}].`,
        channels: [NotificationChannel.WHATSAPP, NotificationChannel.SMS],
        trackingUrl,
      });
    }

    return {
      message: `Job ${job.jobCode} stage successfully updated to ${targetStage}`,
      job: updatedJob,
    };
  }

  /**
   * Find job by QR code token for instant scanner preview
   */
  async findByQrToken(qrCodeToken: string) {
    const job = await this.prisma.jobCard.findUnique({
      where: { qrCodeToken },
      include: {
        customer: true,
        measurements: true,
        stageHistory: { orderBy: { completedAt: 'desc' }, take: 3 },
      },
    });
    if (!job) throw new NotFoundException('Job not found for this QR code');
    return job;
  }

  /**
   * Generate QR Code image data URL for printable job card
   */
  async getQrCodeDataUrl(qrCodeToken: string): Promise<string> {
    return QRCode.toDataURL(qrCodeToken, {
      width: 300,
      margin: 2,
      color: {
        dark: '#002B49',
        light: '#FFFFFF',
      },
    });
  }
}
