import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class CreateConversationDto {
  @ApiProperty({ example: '6523abc...', description: 'ID of the participant to start a chat with' })
  @IsNotEmpty()
  @IsString()
  participantId: string;
}
