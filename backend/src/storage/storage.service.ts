import { Injectable } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class StorageService {
  private readonly uploadDir = process.env.UPLOAD_DESTINATION || './uploads';

  constructor() {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  saveBase64File(base64Data: string, prefix: string = 'file', extension: string = 'png'): string {
    const matches = base64Data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
    const data = matches ? matches[2] : base64Data;
    const fileName = `${prefix}_${Date.now()}_${Math.random().toString(36).substring(7)}.${extension}`;
    const filePath = path.join(this.uploadDir, fileName);

    fs.writeFileSync(filePath, Buffer.from(data, 'base64'));
    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    return `${appUrl}/uploads/${fileName}`;
  }

  getFileUrl(fileName: string): string {
    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    return `${appUrl}/uploads/${fileName}`;
  }
}
