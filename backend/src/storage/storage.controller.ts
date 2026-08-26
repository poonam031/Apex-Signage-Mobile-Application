import { Controller, Post, UseInterceptors, UploadedFile, UseGuards, BadRequestException } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiTags, ApiConsumes, ApiBody, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { diskStorage } from 'multer';
import * as path from 'path';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { StorageService } from './storage.service';

@ApiTags('File Storage')
@Controller('storage')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class StorageController {
  constructor(private storageService: StorageService) {}

  @Post('upload')
  @ApiOperation({ summary: 'Upload photo, annotated image, or 10-second site video' })
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads',
        filename: (req, file, cb) => {
          const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          const ext = path.extname(file.originalname) || '.jpg';
          cb(null, `${file.fieldname}-${uniqueSuffix}${ext}`);
        },
      }),
      limits: {
        fileSize: 25 * 1024 * 1024, // 25MB max
      },
    }),
  )
  uploadFile(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('No file uploaded');
    }
    const appUrl = process.env.APP_URL || 'http://localhost:5000';
    return {
      message: 'File uploaded successfully',
      fileName: file.filename,
      fileUrl: `${appUrl}/uploads/${file.filename}`,
      sizeBytes: file.size,
      mimetype: file.mimetype,
    };
  }
}
