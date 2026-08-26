import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { RewardCategory } from '@prisma/client';

export interface SubmitCustomerFeedbackDto {
  starRating: number; // 1 to 5
  feedbackText?: string;
  signatureBase64?: string; // base64 canvas data
}

@Injectable()
export class TrackingService {
  constructor(
    private prisma: PrismaService,
    private storageService: StorageService,
  ) {}

  async getPublicJobTracking(trackingToken: string) {
    const job = await this.prisma.jobCard.findUnique({
      where: { trackingToken },
      select: {
        jobCode: true,
        boardType: true,
        currentStage: true,
        status: true,
        createdAt: true,
        customer: {
          select: {
            name: true,
            companyName: true,
          },
        },
        assignedInstaller: {
          select: {
            name: true,
            phone: true,
          },
        },
        stageHistory: {
          select: {
            stage: true,
            completedAt: true,
            remarks: true,
          },
          orderBy: { completedAt: 'asc' },
        },
        feedbacks: {
          select: {
            starRating: true,
            feedbackText: true,
            submittedAt: true,
          },
        },
      },
    });

    if (!job) {
      throw new NotFoundException('Tracking link is invalid or expired.');
    }

    return job;
  }

  async submitCustomerFeedback(trackingToken: string, dto: SubmitCustomerFeedbackDto, clientIp?: string) {
    const job = await this.prisma.jobCard.findUnique({
      where: { trackingToken },
      include: { customer: true, assignedInstaller: true },
    });

    if (!job) {
      throw new NotFoundException('Tracking link is invalid.');
    }

    if (dto.starRating < 1 || dto.starRating > 5) {
      throw new BadRequestException('Rating must be between 1 and 5 stars');
    }

    let signatureUrl: string | undefined;
    if (dto.signatureBase64) {
      signatureUrl = this.storageService.saveBase64File(dto.signatureBase64, `sig_${job.jobCode}`, 'png');
    }

    const feedback = await this.prisma.customerFeedback.create({
      data: {
        jobId: job.id,
        customerId: job.customerId,
        starRating: dto.starRating,
        feedbackText: dto.feedbackText,
        signatureUrl,
        customerIp: clientIp,
      },
    });

    // Gamification Rule: Award 150 points for 5-star customer ratings to Installer Lead
    if (dto.starRating === 5 && job.assignedInstallerId) {
      await this.prisma.rewardPoint.create({
        data: {
          userId: job.assignedInstallerId,
          points: 150,
          category: RewardCategory.FIVE_STAR_RATING,
          referenceId: job.id,
          remarks: `5-Star Customer Rating received for ${job.jobCode}`,
        },
      });
    }

    return {
      message: 'Thank you! Your feedback and signature have been recorded.',
      feedback,
    };
  }
}
