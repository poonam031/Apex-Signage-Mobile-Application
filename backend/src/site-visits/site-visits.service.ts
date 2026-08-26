import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CalculationService } from '../common/services/calculation.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SiteVisitStatus, UserRole, NotificationChannel, MediaType } from '@prisma/client';

export interface CreateSiteVisitDto {
  customerId: string;
  assignedToId: string;
  visitDateTime: string | Date;
  siteAddress: string;
  latitude?: number;
  longitude?: number;
  notes?: string;
}

export interface SaveMeasurementDto {
  boardName: string;
  lengthFeet: number;
  heightFeet: number;
  materialType?: string;
  pipeGauge?: string;
  framingType?: string;
  notes?: string;
}

export interface SubmitSiteVisitDto {
  measurements: SaveMeasurementDto[];
  technicalChecklist?: {
    boardFloorHeight?: string;
    powerSupplyDistanceFeet?: number;
    ladderRequired?: boolean;
    craneRequired?: boolean;
    scaffoldingRequired?: boolean;
    obstacles?: string;
    notes?: string;
  };
  mediaList?: Array<{
    mediaType: MediaType;
    fileUrl: string;
    durationSeconds?: number;
    metadata?: string;
  }>;
  notes?: string;
}

@Injectable()
export class SiteVisitsService {
  constructor(
    private prisma: PrismaService,
    private calculationService: CalculationService,
    private notificationsService: NotificationsService,
  ) {}

  async findAll(userId?: string, userRole?: UserRole, status?: SiteVisitStatus) {
    const whereClause: any = {};
    if (userRole === UserRole.FIELD_BOY && userId) {
      whereClause.assignedToId = userId;
    }
    if (status) {
      whereClause.status = status;
    }

    return this.prisma.siteVisit.findMany({
      where: whereClause,
      include: {
        customer: true,
        assignedTo: {
          select: { id: true, name: true, phone: true },
        },
        measurements: true,
        technicalChecklist: true,
        siteMedias: true,
      },
      orderBy: { visitDateTime: 'desc' },
    });
  }

  async findOne(id: string) {
    const visit = await this.prisma.siteVisit.findUnique({
      where: { id },
      include: {
        customer: true,
        assignedTo: {
          select: { id: true, name: true, phone: true, email: true },
        },
        measurements: true,
        technicalChecklist: true,
        siteMedias: true,
        jobCards: true,
      },
    });
    if (!visit) throw new NotFoundException('Site visit not found');
    return visit;
  }

  async create(dto: CreateSiteVisitDto, creatorId: string) {
    const customer = await this.prisma.customer.findUnique({ where: { id: dto.customerId } });
    if (!customer) throw new NotFoundException('Customer not found');

    const siteVisit = await this.prisma.siteVisit.create({
      data: {
        customerId: dto.customerId,
        assignedToId: dto.assignedToId,
        visitDateTime: new Date(dto.visitDateTime),
        siteAddress: dto.siteAddress || customer.address,
        latitude: dto.latitude || customer.latitude,
        longitude: dto.longitude || customer.longitude,
        notes: dto.notes,
        status: SiteVisitStatus.ASSIGNED,
      },
      include: {
        customer: true,
        assignedTo: true,
      },
    });

    // Notify Field Boy
    await this.notificationsService.dispatch({
      userId: dto.assignedToId,
      customerPhone: siteVisit.assignedTo.phone,
      title: '📋 New Site Visit Assigned',
      message: `You have been assigned a site visit for ${customer.name} at ${siteVisit.siteAddress}.`,
      channels: [NotificationChannel.IN_APP, NotificationChannel.WHATSAPP],
      dataPayload: { siteVisitId: siteVisit.id },
    });

    return siteVisit;
  }

  async updateStatus(id: string, status: SiteVisitStatus, updatedById: string) {
    return this.prisma.siteVisit.update({
      where: { id },
      data: { status },
      include: { customer: true, assignedTo: true },
    });
  }

  async submitSiteVisit(id: string, dto: SubmitSiteVisitDto, submittedById: string) {
    const visit = await this.prisma.siteVisit.findUnique({
      where: { id },
      include: { customer: true, assignedTo: true },
    });
    if (!visit) throw new NotFoundException('Site visit not found');

    // 1. Save or replace measurements with auto-calculated Sq.Ft & Sq.M
    await this.prisma.measurement.deleteMany({ where: { siteVisitId: id } });
    if (dto.measurements && dto.measurements.length > 0) {
      for (const m of dto.measurements) {
        const area = this.calculationService.calculateArea(m.lengthFeet, m.heightFeet);
        await this.prisma.measurement.create({
          data: {
            siteVisitId: id,
            boardName: m.boardName || 'Main Sign Board',
            lengthFeet: m.lengthFeet,
            heightFeet: m.heightFeet,
            squareFeet: area.squareFeet,
            squareMeters: area.squareMeters,
            materialType: m.materialType,
            pipeGauge: m.pipeGauge,
            framingType: m.framingType,
            notes: m.notes,
          },
        });
      }
    }

    // 2. Technical Checklist
    if (dto.technicalChecklist) {
      await this.prisma.technicalChecklist.upsert({
        where: { siteVisitId: id },
        create: {
          siteVisitId: id,
          boardFloorHeight: dto.technicalChecklist.boardFloorHeight,
          powerSupplyDistanceFeet: dto.technicalChecklist.powerSupplyDistanceFeet,
          ladderRequired: dto.technicalChecklist.ladderRequired ?? false,
          craneRequired: dto.technicalChecklist.craneRequired ?? false,
          scaffoldingRequired: dto.technicalChecklist.scaffoldingRequired ?? false,
          obstacles: dto.technicalChecklist.obstacles,
          notes: dto.technicalChecklist.notes,
        },
        update: {
          boardFloorHeight: dto.technicalChecklist.boardFloorHeight,
          powerSupplyDistanceFeet: dto.technicalChecklist.powerSupplyDistanceFeet,
          ladderRequired: dto.technicalChecklist.ladderRequired,
          craneRequired: dto.technicalChecklist.craneRequired,
          scaffoldingRequired: dto.technicalChecklist.scaffoldingRequired,
          obstacles: dto.technicalChecklist.obstacles,
          notes: dto.technicalChecklist.notes,
        },
      });
    }

    // 3. Media attachments (photos, annotated images, 10s video)
    if (dto.mediaList && dto.mediaList.length > 0) {
      for (const media of dto.mediaList) {
        await this.prisma.siteMedia.create({
          data: {
            siteVisitId: id,
            mediaType: media.mediaType,
            fileUrl: media.fileUrl,
            durationSeconds: media.durationSeconds,
            metadata: media.metadata,
          },
        });
      }
    }

    // 4. Update Site Visit status to SUBMITTED
    const updatedVisit = await this.prisma.siteVisit.update({
      where: { id },
      data: {
        status: SiteVisitStatus.SUBMITTED,
        notes: dto.notes ? `${visit.notes || ''}\n${dto.notes}` : visit.notes,
      },
      include: {
        customer: true,
        measurements: true,
        technicalChecklist: true,
        siteMedias: true,
      },
    });

    // Notify Designers and Super Admin
    const designers = await this.prisma.user.findMany({
      where: { role: { in: [UserRole.SUPER_ADMIN, UserRole.DESIGNER_OPERATOR] }, isActive: true },
    });

    for (const d of designers) {
      await this.notificationsService.dispatch({
        userId: d.id,
        title: `📐 Site Visit Submitted: ${visit.customer.name}`,
        message: `Field Boy has uploaded measurements and annotated photos for ${visit.customer.name}. Ready for design!`,
        channels: [NotificationChannel.IN_APP],
        dataPayload: { siteVisitId: id },
      });
    }

    return updatedVisit;
  }
}
