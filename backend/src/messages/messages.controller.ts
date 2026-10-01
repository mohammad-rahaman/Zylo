import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { MessagesService } from './messages.service';
import { CreateMessageDto, UpdateMessageStatusDto } from './dto/create-message.dto';
import { GetMessagesQueryDto } from './dto/get-messages-query.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Messages')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  @Get('conversations/:id/messages')
  @ApiOperation({ summary: 'Retrieve paginated message history for a conversation' })
  @ApiResponse({ status: 200, description: 'Paginated messages with nextCursor' })
  async getMessages(
    @Param('id') conversationId: string,
    @CurrentUser('userId') currentUserId: string,
    @Query() query: GetMessagesQueryDto,
  ) {
    return this.messagesService.getMessages(conversationId, currentUserId, query);
  }

  @Post('conversations/:id/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Send a new message to a conversation' })
  @ApiResponse({ status: 201, description: 'Message sent successfully' })
  async sendMessage(
    @Param('id') conversationId: string,
    @CurrentUser('userId') currentUserId: string,
    @Body() dto: CreateMessageDto,
  ) {
    return this.messagesService.sendMessage(conversationId, currentUserId, dto);
  }

  @Patch('messages/:id')
  @ApiOperation({ summary: 'Update message delivery or read receipt status' })
  @ApiResponse({ status: 200, description: 'Status updated' })
  async updateStatus(
    @Param('id') messageId: string,
    @CurrentUser('userId') currentUserId: string,
    @Body() dto: UpdateMessageStatusDto,
  ) {
    return this.messagesService.updateMessageStatus(messageId, currentUserId, dto);
  }

  @Delete('messages/:id')
  @ApiOperation({ summary: 'Delete a message' })
  @ApiResponse({ status: 200, description: 'Message deleted' })
  async deleteMessage(
    @Param('id') messageId: string,
    @CurrentUser('userId') currentUserId: string,
  ) {
    return this.messagesService.deleteMessage(messageId, currentUserId);
  }
}
