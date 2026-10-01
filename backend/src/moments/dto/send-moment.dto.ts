import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
  ArrayNotEmpty,
} from 'class-validator';

export class SendMomentDto {
  @ApiProperty({ description: 'URL of the single uploaded media item' })
  @IsString()
  @IsNotEmpty()
  mediaUrl: string;

  @ApiProperty({ description: 'List of target recipient user IDs', type: [String] })
  @IsArray()
  @IsString({ each: true })
  @ArrayNotEmpty()
  recipientIds: string[];

  @ApiPropertyOptional({ description: 'Optional text caption for the Moment' })
  @IsOptional()
  @IsString()
  caption?: string;

  @ApiPropertyOptional({ description: 'Optional visual filter identifier (e.g. orange_pop, sunset)' })
  @IsOptional()
  @IsString()
  filter?: string;
}
