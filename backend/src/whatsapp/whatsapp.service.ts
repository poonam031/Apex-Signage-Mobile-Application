import { Injectable, Logger } from '@nestjs/common';

export interface SendWhatsAppMessageDto {
  toPhone: string;
  templateName?: string;
  parameters?: Record<string, string>;
  messageText?: string;
  mediaUrl?: string;
}

@Injectable()
export class WhatsAppService {
  private readonly logger = new Logger(WhatsAppService.name);
  private readonly provider = process.env.WHATSAPP_PROVIDER || 'MOCK';

  async sendMessage(dto: SendWhatsAppMessageDto): Promise<{ success: boolean; messageId: string }> {
    const formattedPhone = dto.toPhone.replace(/\D/g, '');
    this.logger.log(`[WhatsApp Provider: ${this.provider}] Sending to ${formattedPhone}: ${dto.messageText || dto.templateName}`);

    // In production with WATI / Gupshup / WhatsApp Cloud API, this invokes external HTTP API
    // For local/development, we simulate immediate successful delivery and generate unique messageId
    const messageId = `wa_msg_${Date.now()}_${Math.random().toString(36).substr(2, 6)}`;
    
    return {
      success: true,
      messageId,
    };
  }

  async sendJobStageUpdate(customerPhone: string, customerName: string, jobCode: string, stage: string, trackingUrl: string) {
    const messageText = `Hello ${customerName}, your signage project [${jobCode}] is now at stage: *${stage}*.\n\nTrack your live project progress here:\n${trackingUrl}\n\n- Apex Signage Team`;
    return this.sendMessage({
      toPhone: customerPhone,
      messageText,
    });
  }

  async sendInvoicePdf(customerPhone: string, customerName: string, invoiceNumber: string, amount: number, pdfUrl: string) {
    const messageText = `Dear ${customerName}, please find attached your Invoice *#${invoiceNumber}* for amount *₹${amount.toLocaleString()}*.\n\nDownload PDF: ${pdfUrl}\n\nThank you for choosing Apex Signage!`;
    return this.sendMessage({
      toPhone: customerPhone,
      messageText,
      mediaUrl: pdfUrl,
    });
  }
}
