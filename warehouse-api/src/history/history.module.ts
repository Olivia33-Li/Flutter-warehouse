import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HistoryController } from './history.controller';
import { HistoryService } from './history.service';
import { ChangeRecord, ChangeRecordSchema } from '../schemas/change-record.schema';

@Module({
  imports: [
    MongooseModule.forFeature([{ name: ChangeRecord.name, schema: ChangeRecordSchema }]),
  ],
  controllers: [HistoryController],
  providers: [HistoryService],
  exports: [HistoryService],
})
export class HistoryModule {}
