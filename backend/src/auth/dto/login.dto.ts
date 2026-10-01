import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'john@example.com or johndoe', description: 'Email address or username' })
  @IsNotEmpty()
  @IsString()
  login: string;

  @ApiProperty({ example: 'Password123!', description: 'Account password' })
  @IsNotEmpty()
  @IsString()
  password: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'The long-lived refresh token' })
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}
