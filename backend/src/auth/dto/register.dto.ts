import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'johndoe', description: 'Unique alphanumeric username' })
  @IsNotEmpty()
  @IsString()
  @Length(3, 30)
  @Matches(/^[a-zA-Z0-9_]+$/, { message: 'Username can only contain letters, numbers, and underscores' })
  username: string;

  @ApiProperty({ example: 'John Doe', description: 'Full display name' })
  @IsNotEmpty()
  @IsString()
  @Length(2, 50)
  displayName: string;

  @ApiProperty({ example: 'john@example.com', description: 'Valid email address' })
  @IsNotEmpty()
  @IsEmail()
  email: string;

  @ApiProperty({ example: 'Password123!', description: 'Strong password (min 6 characters)' })
  @IsNotEmpty()
  @IsString()
  @Length(6, 100)
  password: string;
}
