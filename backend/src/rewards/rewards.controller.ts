import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { RewardsService, AddRewardPointsDto } from './rewards.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserRole } from '@prisma/client';

@ApiTags('Incentives & Gamification Leaderboard')
@Controller('rewards')
@UseGuards(JwtAuthGuard, RolesGuard)
@ApiBearerAuth()
export class RewardsController {
  constructor(private rewardsService: RewardsService) {}

  @Get('my-points')
  @ApiOperation({ summary: 'Get current user reward points balance and history' })
  async getMyPoints(@CurrentUser('id') userId: string) {
    return this.rewardsService.getUserPoints(userId);
  }

  @Get('leaderboard')
  @ApiOperation({ summary: 'Get monthly employee performance leaderboard' })
  @ApiQuery({ name: 'monthYear', required: false, example: '2026-08' })
  async getLeaderboard(@Query('monthYear') monthYear?: string) {
    return this.rewardsService.getLeaderboard(monthYear);
  }

  @Post('add-points')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Manually award or adjust reward points (Super Admin)' })
  async addPoints(@Body() dto: AddRewardPointsDto) {
    return this.rewardsService.addPoints(dto);
  }

  @Post('employee-of-month')
  @Roles(UserRole.SUPER_ADMIN)
  @ApiOperation({ summary: 'Designate Employee of the Month and configure cash bonus' })
  async setEmployeeOfMonth(
    @Body('userId') userId: string,
    @Body('monthYear') monthYear: string,
    @Body('rewardAmount') rewardAmount?: number,
  ) {
    return this.rewardsService.setEmployeeOfMonth(userId, monthYear, rewardAmount);
  }
}
