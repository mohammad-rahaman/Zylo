import { Controller, Post, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { SaveDeviceTokenDto } from './dto/save-device-token.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('Notifications')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('device-token')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Register or refresh an FCM device push token' })
  @ApiResponse({ status: 200, description: 'Device token saved successfully' })
  async saveDeviceToken(
    @CurrentUser('userId') currentUserId: string,
    @Body() dto: SaveDeviceTokenDto,
  ) {
    await this.notificationsService.saveDeviceToken(
      currentUserId,
      dto.token,
      dto.platform,
    );
    return { success: true, message: 'Device token registered' };
  }
}
