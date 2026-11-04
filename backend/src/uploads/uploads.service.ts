import {
  Injectable,
  BadRequestException,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import * as fs from 'fs';
import * as path from 'path';

export interface UploadResult {
  url: string;
  fileName: string;
  fileSize: number;
  mimeType: string;
  width?: number;
  height?: number;
  duration?: number;
}

@Injectable()
export class UploadsService {
  private readonly logger = new Logger(UploadsService.name);
  private isCloudinaryConfigured = false;

  constructor(private configService: ConfigService) {
    const cloudName = this.configService.get<string>('uploads.cloudinary.cloudName');
    const apiKey = this.configService.get<string>('uploads.cloudinary.apiKey');
    const apiSecret = this.configService.get<string>('uploads.cloudinary.apiSecret');

    if (cloudName && apiKey && apiSecret) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
      });
      this.isCloudinaryConfigured = true;
      this.logger.log('Cloudinary storage driver configured');
    } else {
      this.logger.log('Cloudinary keys not set; using local filesystem storage driver');
      const uploadDir = this.configService.get<string>('uploads.destination', './uploads');
      if (!fs.existsSync(uploadDir)) {
        fs.mkdirSync(uploadDir, { recursive: true });
      }
    }
  }

  async handleUpload(file: Express.Multer.File, userId: string): Promise<UploadResult> {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    // Allowed mime types: images, audio, video, pdf, office docs, archives
    const allowedMimeRegex = /^(image\/(jpeg|png|webp|gif)|video\/(mp4|quicktime|webm)|audio\/(mpeg|mp4|ogg|wav)|application\/(pdf|zip|msword|vnd\.openxmlformats-officedocument\.wordprocessingml\.document))$/;
    if (!allowedMimeRegex.test(file.mimetype)) {
      throw new BadRequestException(
        `Unsupported file type: ${file.mimetype}. Allowed types include JPEG, PNG, WEBP, GIF, MP4, PDF, DOCX, ZIP`,
      );
    }

    const maxSize = this.configService.get<number>('uploads.maxSizeBytes', 25 * 1024 * 1024);
    if (file.size > maxSize) {
      throw new BadRequestException(`File size exceeds limit of ${maxSize / (1024 * 1024)}MB`);
    }

    if (this.isCloudinaryConfigured) {
      return this.uploadToCloudinary(file, userId);
    }

    // Local disk storage is a development-only fallback. In production we
    // require Cloudinary so that uploads return publicly accessible URLs.
    if (process.env.NODE_ENV === 'production') {
      this.logger.error(
        'Upload rejected: Cloudinary is not configured in production. Set CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY and CLOUDINARY_API_SECRET.',
      );
      throw new InternalServerErrorException('Media storage is not configured');
    }

    return this.saveToLocal(file, userId);
  }

  private async uploadToCloudinary(file: Express.Multer.File, userId: string): Promise<UploadResult> {
    return new Promise((resolve, reject) => {
      const resourceType = file.mimetype.startsWith('video/')
        ? 'video'
        : file.mimetype.startsWith('image/')
          ? 'image'
          : 'raw';

      const uploadStream = cloudinary.uploader.upload_stream(
        {
          folder: `zylo/users/${userId}`,
          resource_type: resourceType,
        },
        (error, result) => {
          if (error || !result) {
            this.logger.error(`Cloudinary upload failed: ${error?.message || 'Empty response'}`);
            return reject(new BadRequestException('Failed to upload file to Cloudinary'));
          }
          resolve({
            url: result.secure_url,
            fileName: file.originalname,
            fileSize: file.size,
            mimeType: file.mimetype,
            width: result.width,
            height: result.height,
            duration: result.duration,
          });
        },
      );

      uploadStream.end(file.buffer);
    });
  }

  private async saveToLocal(file: Express.Multer.File, userId: string): Promise<UploadResult> {
    const uploadDir = this.configService.get<string>('uploads.destination', './uploads');
    const userDir = path.join(uploadDir, userId);
    if (!fs.existsSync(userDir)) {
      fs.mkdirSync(userDir, { recursive: true });
    }

    const ext = path.extname(file.originalname);
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const filename = `${uniqueSuffix}${ext}`;
    const filePath = path.join(userDir, filename);

    await fs.promises.writeFile(filePath, file.buffer);

    // Development-only URL. The Flutter client rewrites this localhost origin
    // to whatever host the device can actually reach (see ApiConstants).
    const port = this.configService.get<number>('port', 3000);
    const url = `http://localhost:${port}/uploads/${userId}/${filename}`;

    return {
      url,
      fileName: file.originalname,
      fileSize: file.size,
      mimeType: file.mimetype,
    };
  }
}
