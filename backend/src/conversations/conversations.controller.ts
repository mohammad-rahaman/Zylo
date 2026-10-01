import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { ConversationsService } from './conversations.service';
import { CreateConversationDto } from './dto/create-conversation.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Conversations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('conversations')
export class ConversationsController {
  constructor(private readonly conversationsService: ConversationsService) {}

  @Get()
  @ApiOperation({ summary: 'List all conversations for the current user' })
  @ApiResponse({ status: 200, description: 'List of conversations' })
  async getConversations(@CurrentUser('userId') currentUserId: string) {
    return this.conversationsService.getUserConversations(currentUserId);
  }

  @Post()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Create or get existing one-on-one conversation' })
  @ApiResponse({ status: 200, description: 'Conversation details' })
  async createConversation(
    @CurrentUser('userId') currentUserId: string,
    @Body() dto: CreateConversationDto,
  ) {
    return this.conversationsService.getOrCreateOneToOne(currentUserId, dto.participantId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get details of a specific conversation' })
  @ApiResponse({ status: 200, description: 'Conversation details' })
  @ApiResponse({ status: 404, description: 'Conversation not found' })
  async getConversation(
    @Param('id') id: string,
    @CurrentUser('userId') currentUserId: string,
  ) {
    return this.conversationsService.getConversationById(id, currentUserId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete conversation and its message history' })
  @ApiResponse({ status: 200, description: 'Conversation deleted' })
  async deleteConversation(
    @Param('id') id: string,
    @CurrentUser('userId') currentUserId: string,
  ) {
    return this.conversationsService.deleteConversation(id, currentUserId);
  }
}
