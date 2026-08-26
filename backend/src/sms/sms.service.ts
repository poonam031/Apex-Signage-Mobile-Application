import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class SmsService {
  private readonly logger = new Logger(SmsService.name);
  private readonly provider = process.env.SMS_PROVIDER || 'MOCK';

  async sendSms(toPhone: string, message: string): Promise<{ success: boolean; messageId: string }> {
    const formattedPhone = toPhone.replace(/\D/g, '');
    this.logger.log(`[SMS Provider: ${this.provider}] Sending to ${formattedPhone}: ${message}`);

    const messageId = `sms_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    return {
      success: true,
      messageId,
    };
  }
}
