import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { Inventory, InventorySchema } from '../schemas/inventory.schema';
import { Sku, SkuSchema } from '../schemas/sku.schema';
import { Location, LocationSchema } from '../schemas/location.schema';
import { HistoryModule } from '../history/history.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Inventory.name, schema: InventorySchema },
      { name: Sku.name, schema: SkuSchema },
      { name: Location.name, schema: LocationSchema },
    ]),
    HistoryModule,
  ],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [InventoryService],
})
export class InventoryModule {}
