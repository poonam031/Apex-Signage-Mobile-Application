import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { CommonModule } from './common/common.module';
import { StorageModule } from './storage/storage.module';
import { NotificationsModule } from './notifications/notifications.module';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { CustomersModule } from './customers/customers.module';
import { SiteVisitsModule } from './site-visits/site-visits.module';
import { JobsModule } from './jobs/jobs.module';
import { DprModule } from './dpr/dpr.module';
import { MachinesModule } from './machines/machines.module';
import { InventoryModule } from './inventory/inventory.module';
import { AttendanceModule } from './attendance/attendance.module';
import { SalaryModule } from './salary/salary.module';
import { RewardsModule } from './rewards/rewards.module';
import { QuotationsModule } from './quotations/quotations.module';
import { InvoicesModule } from './invoices/invoices.module';
import { PaymentsModule } from './payments/payments.module';
import { PettyCashModule } from './petty-cash/petty-cash.module';
import { TrackingModule } from './tracking/tracking.module';
import { ReportsModule } from './reports/reports.module';
import { SettingsModule } from './settings/settings.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    CommonModule,
    StorageModule,
    NotificationsModule,
    AuditModule,
    AuthModule,
    UsersModule,
    CustomersModule,
    SiteVisitsModule,
    JobsModule,
    DprModule,
    MachinesModule,
    InventoryModule,
    AttendanceModule,
    SalaryModule,
    RewardsModule,
    QuotationsModule,
    InvoicesModule,
    PaymentsModule,
    PettyCashModule,
    TrackingModule,
    ReportsModule,
    SettingsModule,
  ],
})
export class AppModule {}
