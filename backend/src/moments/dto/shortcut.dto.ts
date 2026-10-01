import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsNotEmpty,
  IsOptional,
  IsString,
} from 'class-validator';

export class CreateShortcutDto {
  @ApiProperty({ description: 'Name of the shortcut, e.g. Besties, Family' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiPropertyOptional({ description: 'Emoji icon for shortcut, default ✨' })
  @IsOptional()
  @IsString()
  emoji?: string;

  @ApiPropertyOptional({ description: 'User IDs in this shortcut', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  contactIds?: string[];
}

export class UpdateShortcutDto {
  @ApiPropertyOptional({ description: 'Name of the shortcut' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: 'Emoji icon for shortcut' })
  @IsOptional()
  @IsString()
  emoji?: string;

  @ApiPropertyOptional({ description: 'User IDs in this shortcut', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  contactIds?: string[];
}
