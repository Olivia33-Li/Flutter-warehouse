import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ExportController } from './export.controller';
import { ExportService } from './export.service';
import { Sku, SkuSchema } from '../schemas/sku.schema';
import { Location, LocationSchema } from '../schemas/location.schema';
import { Inventory, InventorySchema } from '../schemas/inventory.schema';
import { ChangeRecord, ChangeRecordSchema } from '../schemas/change-record.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Sku.name, schema: SkuSchema },
      { name: Location.name, schema: LocationSchema },
      { name: Inventory.name, schema: InventorySchema },
      { name: ChangeRecord.name, schema: ChangeRecordSchema },
    ]),
  ],
  controllers: [ExportController],
  providers: [ExportService],
})
export class ExportModule {}
