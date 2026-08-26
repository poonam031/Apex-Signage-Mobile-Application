import { Global, Module } from '@nestjs/common';
import { CalculationService } from './services/calculation.service';
import { RolesGuard } from './guards/roles.guard';

@Global()
@Module({
  providers: [CalculationService, RolesGuard],
  exports: [CalculationService, RolesGuard],
})
export class CommonModule {}
