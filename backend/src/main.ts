import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { NestExpressApplication } from '@nestjs/platform-express';
import helmet from 'helmet';
import * as path from 'path';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  const configService = app.get(ConfigService);

  const port = configService.get<number>('port', 3000);
  const apiPrefix = configService.get<string>('apiPrefix', 'api/v1');
  const corsOrigin = configService.get<string>('corsOrigin', '*');

  // Security Headers
  app.use(
    helmet({
      crossOriginResourcePolicy: false,
    }),
  );

  // CORS Configuration
  app.enableCors({
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Global Exception Filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // Static Assets (uploads directory)
  const uploadDir = configService.get<string>('uploads.destination', './uploads');
  app.useStaticAssets(path.resolve(uploadDir), {
    prefix: '/uploads/',
  });

  // Global API Route Prefix
  app.setGlobalPrefix(apiPrefix);

  // Swagger OpenAPI Documentation
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Zylo Messaging API')
    .setDescription(
      'Comprehensive REST and Realtime Messaging API documentation for Zylo Application',
    )
    .setVersion('1.0.0')
    .addBearerAuth()
    .addTag('Authentication', 'User registration, login, token refresh, and logout')
    .addTag('Users', 'User discovery, profile updates, and block management')
    .addTag('Conversations', 'One-on-one conversations management and participant retrieval')
    .addTag('Messages', 'Realtime messages, cursor-based pagination, and message actions')
    .addTag('Uploads', 'Image, video, audio, and document uploads')
    .addTag('Notifications', 'Device FCM token registration and push notifications')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('api/docs', app, document);

  await app.listen(port, '0.0.0.0');
  logger.log(`Zylo backend server is running on: http://0.0.0.0:${port}/${apiPrefix}`);
  logger.log(`Swagger OpenAPI Documentation available at: http://localhost:${port}/api/docs`);
}
bootstrap();
