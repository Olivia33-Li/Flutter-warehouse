import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { SkusController } from './skus.controller';
import { SkusService } from './skus.service';
import { Sku, SkuSchema } from '../schemas/sku.schema';
import { Inventory, InventorySchema } from '../schemas/inventory.schema';
import { HistoryModule } from '../history/history.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Sku.name, schema: SkuSchema },
      { name: Inventory.name, schema: InventorySchema },
    ]),
    HistoryModule,
  ],
  controllers: [SkusController],
  providers: [SkusService],
  exports: [SkusService],
})
export class SkusModule {}
