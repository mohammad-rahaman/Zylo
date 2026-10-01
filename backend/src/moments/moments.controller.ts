import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { MomentsService } from './moments.service';
import { SendMomentDto } from './dto/send-moment.dto';
import { CreateShortcutDto, UpdateShortcutDto } from './dto/shortcut.dto';
import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class StartMomentDto {
  @ApiProperty({ description: 'The user ID to start a Moment with' })
  @IsString()
  @IsNotEmpty()
  targetUserId: string;
}

@ApiTags('Moments')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('moments')
export class MomentsController {
  constructor(private readonly momentsService: MomentsService) {}

  @Post()
  @ApiOperation({ summary: 'Start a new Moment with a user' })
  async startMoment(
    @CurrentUser('userId') userId: string,
    @Body() dto: StartMomentDto,
  ) {
    return this.momentsService.startMoment(userId, dto.targetUserId);
  }

  @Post('send')
  @ApiOperation({ summary: 'Send captured Moment media to one or multiple recipients' })
  async sendMoment(
    @CurrentUser('userId') userId: string,
    @Body() dto: SendMomentDto,
  ) {
    return this.momentsService.sendMoment(userId, dto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all active Moments for the current user' })
  async getMyMoments(@CurrentUser('userId') userId: string) {
    return this.momentsService.getUserMoments(userId);
  }

  @Get('shortcuts')
  @ApiOperation({ summary: 'Get all Quick Send shortcuts for current user' })
  async getShortcuts(@CurrentUser('userId') userId: string) {
    return this.momentsService.getShortcuts(userId);
  }

  @Post('shortcuts')
  @ApiOperation({ summary: 'Create a new Quick Send shortcut' })
  async createShortcut(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateShortcutDto,
  ) {
    return this.momentsService.createShortcut(userId, dto);
  }

  @Patch('shortcuts/:id')
  @ApiOperation({ summary: 'Update a Quick Send shortcut' })
  async updateShortcut(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateShortcutDto,
  ) {
    return this.momentsService.updateShortcut(userId, id, dto);
  }

  @Delete('shortcuts/:id')
  @ApiOperation({ summary: 'Delete a Quick Send shortcut' })
  async deleteShortcut(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.momentsService.deleteShortcut(userId, id);
  }

  @Get('with/:targetUserId')
  @ApiOperation({ summary: 'Get active Moment with a specific user' })
  async getMomentWithUser(
    @CurrentUser('userId') userId: string,
    @Param('targetUserId') targetUserId: string,
  ) {
    return this.momentsService.getMomentWithUser(userId, targetUserId);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'End / remove an active Moment' })
  async endMoment(
    @CurrentUser('userId') userId: string,
    @Param('id') id: string,
  ) {
    return this.momentsService.endMoment(id, userId);
  }
}
