import { Global, Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { WhatsAppService } from '../whatsapp/whatsapp.service';
import { SmsService } from '../sms/sms.service';

@Global()
@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, WhatsAppService, SmsService],
  exports: [NotificationsService, WhatsAppService, SmsService],
})
export class NotificationsModule {}
