import { Controller, Get } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('Health')
@Controller('health')
export class HealthController {
  @Get()
  @ApiOperation({ summary: 'Public liveness/health check' })
  check() {
    return { status: 'ok', uptime: process.uptime() };
  }
}
