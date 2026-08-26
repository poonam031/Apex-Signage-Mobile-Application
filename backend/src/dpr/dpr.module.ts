import { Module } from '@nestjs/common';
import { DprService } from './dpr.service';
import { DprController } from './dpr.controller';

@Module({
  controllers: [DprController],
  providers: [DprService],
  exports: [DprService],
})
export class DprModule {}
