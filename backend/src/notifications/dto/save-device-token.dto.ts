import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class SaveDeviceTokenDto {
  @ApiProperty({ description: 'FCM Registration Token' })
  @IsNotEmpty()
  @IsString()
  token: string;

  @ApiProperty({ example: 'android', required: false })
  @IsOptional()
  @IsString()
  platform?: string;
}
