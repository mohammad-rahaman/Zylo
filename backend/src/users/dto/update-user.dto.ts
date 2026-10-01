import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Length } from 'class-validator';

export class UpdateUserDto {
  @ApiPropertyOptional({ example: 'John Doe' })
  @IsOptional()
  @IsString()
  @Length(2, 50)
  displayName?: string;

  @ApiPropertyOptional({ example: 'Available' })
  @IsOptional()
  @IsString()
  @Length(0, 150)
  bio?: string;

  @ApiPropertyOptional({ example: 'https://res.cloudinary.com/.../profile.jpg' })
  @IsOptional()
  @IsString()
  profilePhoto?: string;
}

export class SearchUserDto {
  @ApiPropertyOptional({ example: 'john', description: 'Username or name query' })
  @IsOptional()
  @IsString()
  q?: string;
}
