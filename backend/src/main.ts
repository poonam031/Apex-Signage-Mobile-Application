import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { NestExpressApplication } from '@nestjs/platform-express';
import * as path from 'path';
import * as fs from 'fs';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const logger = new Logger('SignageApiBootstrap');

  // Enable CORS for mobile app and web clients
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global Validation Pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  // Global API Prefix
  const apiPrefix = process.env.API_PREFIX || 'api/v1';
  app.setGlobalPrefix(apiPrefix);

  // Serve static uploaded files (photos, annotated images, videos, PDFs)
  const uploadDir = path.resolve(process.env.UPLOAD_DESTINATION || './uploads');
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }
  app.useStaticAssets(uploadDir, {
    prefix: '/uploads/',
  });

  // Swagger / OpenAPI Setup
  const config = new DocumentBuilder()
    .setTitle('Printing & Signage Management API')
    .setDescription(
      'Production REST API for Complete Printing & Signage Business Operations: Site Visits, Smart Measurements, Job Cards, DPR, Inventory, Smart Attendance (200m Geofence/QR), Rewards, Billing & Live Customer Tracking.',
    )
    .setVersion('1.0.0')
    .addBearerAuth()
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    customSiteTitle: 'Printing & Signage Management API Docs',
  });

  const port = process.env.PORT || 5000;
  await app.listen(port);

  logger.log(`🚀 Printing & Signage Backend API is running on: http://localhost:${port}/${apiPrefix}`);
  logger.log(`📚 Swagger OpenAPI Documentation available at: http://localhost:${port}/api/docs`);
  logger.log(`📁 Media upload destination: ${uploadDir}`);
}

bootstrap();
