import { Controller, Get, Post, Body, Param, Req, Ip } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { TrackingService, SubmitCustomerFeedbackDto } from './tracking.service';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('Customer Live Tracking Portal (Public)')
@Controller('tracking')
export class TrackingController {
  constructor(private trackingService: TrackingService) {}

  @Public()
  @Get(':token')
  @ApiOperation({ summary: 'Public endpoint: Customer tracks live signage project stage and delivery status' })
  @ApiResponse({ status: 200, description: 'Real-time project progress timeline' })
  async getTracking(@Param('token') token: string) {
    return this.trackingService.getPublicJobTracking(token);
  }

  @Public()
  @Post(':token/feedback')
  @ApiOperation({ summary: 'Public endpoint: Customer submits 1-5 star rating, comments & digital signature' })
  async submitFeedback(
    @Param('token') token: string,
    @Body() dto: SubmitCustomerFeedbackDto,
    @Ip() clientIp: string,
  ) {
    return this.trackingService.submitCustomerFeedback(token, dto, clientIp);
  }
}
