import {
  Controller,
  Get,
  Patch,
  Post,
  Delete,
  Param,
  Query,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Users')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('search')
  @ApiOperation({ summary: 'Search users by username, display name, or email' })
  @ApiResponse({ status: 200, description: 'List of matching users' })
  async search(@Query('q') query: string, @CurrentUser('userId') currentUserId: string) {
    return this.usersService.searchUsers(query, currentUserId);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get current authenticated user profile' })
  @ApiResponse({ status: 200, description: 'Current user profile' })
  async getMe(@CurrentUser('userId') currentUserId: string) {
    return this.usersService.getUserById(currentUserId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update current user profile (name, bio, photo)' })
  @ApiResponse({ status: 200, description: 'Updated user profile' })
  async updateMe(
    @CurrentUser('userId') currentUserId: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.updateMe(currentUserId, dto);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get another user profile by ID' })
  @ApiResponse({ status: 200, description: 'User profile with live presence' })
  @ApiResponse({ status: 404, description: 'User not found' })
  async getUser(
    @Param('id') targetId: string,
    @CurrentUser('userId') currentUserId: string,
  ) {
    return this.usersService.getUserById(targetId, currentUserId);
  }

  @Post(':id/block')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Block a user' })
  @ApiResponse({ status: 200, description: 'User blocked' })
  async blockUser(
    @Param('id') targetId: string,
    @CurrentUser('userId') currentUserId: string,
  ) {
    return this.usersService.blockUser(currentUserId, targetId);
  }

  @Delete(':id/block')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Unblock a user' })
  @ApiResponse({ status: 200, description: 'User unblocked' })
  async unblockUser(
    @Param('id') targetId: string,
    @CurrentUser('userId') currentUserId: string,
  ) {
    return this.usersService.unblockUser(currentUserId, targetId);
  }
}
