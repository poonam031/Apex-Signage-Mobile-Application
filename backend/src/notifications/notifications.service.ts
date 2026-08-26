import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { SmsService } from '../sms/sms.service';
import { NotificationChannel } from '@prisma/client';

export interface DispatchNotificationDto {
  userId?: string;
  customerPhone?: string;
  customerName?: string;
  title: string;
  message: string;
  type?: string;
  channels: NotificationChannel[];
  dataPayload?: Record<string, any>;
  trackingUrl?: string;
  pdfUrl?: string;
}

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private whatsappService: WhatsAppService,
    private smsService: SmsService,
  ) {}

  async dispatch(dto: DispatchNotificationDto) {
    const results: Record<string, any> = {};

    // 1. In-App Notification (if userId present)
    if (dto.userId && dto.channels.includes(NotificationChannel.IN_APP)) {
      const notif = await this.prisma.notification.create({
        data: {
          userId: dto.userId,
          title: dto.title,
          message: dto.message,
          type: dto.type || 'GENERAL',
          channel: NotificationChannel.IN_APP,
          dataPayload: dto.dataPayload ? JSON.stringify(dto.dataPayload) : null,
        },
      });
      results.inApp = notif;
    }

    // 2. WhatsApp Notification
    if (dto.customerPhone && dto.channels.includes(NotificationChannel.WHATSAPP)) {
      const waRes = await this.whatsappService.sendMessage({
        toPhone: dto.customerPhone,
        messageText: `${dto.title}\n\n${dto.message}${dto.trackingUrl ? `\n\nTrack: ${dto.trackingUrl}` : ''}`,
        mediaUrl: dto.pdfUrl,
      });
      results.whatsapp = waRes;
    }

    // 3. SMS Notification
    if (dto.customerPhone && dto.channels.includes(NotificationChannel.SMS)) {
      const smsRes = await this.smsService.sendSms(dto.customerPhone, `${dto.title}: ${dto.message}`);
      results.sms = smsRes;
    }

    return { success: true, results };
  }

  async getUserNotifications(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markAsRead(notificationId: string, userId: string) {
    return this.prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: { isRead: true },
    });
  }

  async markAllAsRead(userId: string) {
    return this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }
}
