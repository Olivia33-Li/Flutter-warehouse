import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { Inventory, InventorySchema } from '../schemas/inventory.schema';
import { Sku, SkuSchema } from '../schemas/sku.schema';
import { Location, LocationSchema } from '../schemas/location.schema';
import { ImportLog, ImportLogSchema } from '../schemas/import-log.schema';
import { InventoryTransaction, InventoryTransactionSchema } from '../schemas/inventory-transaction.schema';
import { HistoryModule } from '../history/history.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Inventory.name, schema: InventorySchema },
      { name: Sku.name, schema: SkuSchema },
      { name: Location.name, schema: LocationSchema },
      { name: ImportLog.name, schema: ImportLogSchema },
      { name: InventoryTransaction.name, schema: InventoryTransactionSchema },
    ]),
    HistoryModule,
  ],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [InventoryService],
})
export class InventoryModule {}
