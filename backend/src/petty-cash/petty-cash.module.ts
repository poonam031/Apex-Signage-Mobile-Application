import { Module } from '@nestjs/common';
import { PettyCashService } from './petty-cash.service';
import { PettyCashController } from './petty-cash.controller';

@Module({
  controllers: [PettyCashController],
  providers: [PettyCashService],
  exports: [PettyCashService],
})
export class PettyCashModule {}
