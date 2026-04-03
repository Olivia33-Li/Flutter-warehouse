import { Module } from '@nestjs/common';
import { TransactionsController } from './transactions.controller';
import { InventoryModule } from '../inventory/inventory.module';

@Module({
  imports: [InventoryModule],
  controllers: [TransactionsController],
})
export class TransactionsModule {}
