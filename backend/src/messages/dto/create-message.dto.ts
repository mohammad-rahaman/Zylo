import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MessageType, MessageStatus } from '../../database/schemas/message.schema';

export class MediaMetadataDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  fileName?: string;

  @ApiPropertyOptional()
  @IsOptional()
  fileSize?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  mimeType?: string;

  @ApiPropertyOptional()
  @IsOptional()
  duration?: number;

  @ApiPropertyOptional()
  @IsOptional()
  width?: number;

  @ApiPropertyOptional()
  @IsOptional()
  height?: number;
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  filter?: string;
}

export class CreateMessageDto {
  @ApiProperty({ enum: MessageType, default: MessageType.TEXT })
  @IsEnum(MessageType)
  type: MessageType;

  @ApiPropertyOptional({ example: 'Hello there!' })
  @IsOptional()
  @IsString()
  content?: string;

  @ApiPropertyOptional({ example: 'https://...' })
  @IsOptional()
  @IsString()
  mediaUrl?: string;

  @ApiPropertyOptional({ type: MediaMetadataDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => MediaMetadataDto)
  mediaMetadata?: MediaMetadataDto;

  @ApiPropertyOptional({ description: 'ID of message being replied to' })
  @IsOptional()
  @IsString()
  replyToId?: string;
}

export class UpdateMessageStatusDto {
  @ApiProperty({ enum: MessageStatus })
  @IsEnum(MessageStatus)
  status: MessageStatus;
}
