import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ImportController } from './import.controller';
import { ImportService } from './import.service';
import { Sku, SkuSchema } from '../schemas/sku.schema';
import { Location, LocationSchema } from '../schemas/location.schema';
import { Inventory, InventorySchema } from '../schemas/inventory.schema';
import { HistoryModule } from '../history/history.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Sku.name, schema: SkuSchema },
      { name: Location.name, schema: LocationSchema },
      { name: Inventory.name, schema: InventorySchema },
    ]),
    HistoryModule,
  ],
  controllers: [ImportController],
  providers: [ImportService],
})
export class ImportModule {}
