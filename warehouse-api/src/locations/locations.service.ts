import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { Location, LocationDocument } from '../schemas/location.schema';
import { Inventory, InventoryDocument } from '../schemas/inventory.schema';
import { HistoryService } from '../history/history.service';
import { CreateLocationDto, UpdateLocationDto } from './dto/location.dto';

@Injectable()
export class LocationsService {
  constructor(
    @InjectModel(Location.name) private locationModel: Model<LocationDocument>,
    @InjectModel(Inventory.name) private inventoryModel: Model<InventoryDocument>,
    private historyService: HistoryService,
  ) {}

  async findAll(search?: string) {
    const filter: any = {};
    if (search) {
      filter.$or = [
        { code: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
      ];
    }
    return this.locationModel.find(filter).lean();
  }

  async findOne(id: string) {
    const location = await this.locationModel.findById(id).lean();
    if (!location) throw new NotFoundException('位置不存在');

    const inventory = await this.inventoryModel
      .find({ locationId: new Types.ObjectId(id) })
      .populate('skuId', 'sku name barcode cartonQty')
      .lean();

    const totalQty = inventory.reduce((sum, r) => sum + r.quantity, 0);
    const skuCount = inventory.length;

    return { ...location, inventory, totalQty, skuCount };
  }

  async create(dto: CreateLocationDto, user: any) {
    const exists = await this.locationModel.findOne({ code: dto.code.toUpperCase() });
    if (exists) throw new ConflictException('位置代码已存在');

    const location = await this.locationModel.create({ ...dto, code: dto.code.toUpperCase() });

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'add',
      entity: 'location',
      description: `新增位置: ${location.code}`,
    });

    return location;
  }

  async update(id: string, dto: UpdateLocationDto, user: any) {
    const location = await this.locationModel.findByIdAndUpdate(id, dto, { new: true });
    if (!location) throw new NotFoundException('位置不存在');

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'edit',
      entity: 'location',
      description: `编辑位置: ${location.code}`,
    });

    return location;
  }

  async remove(id: string, user: any) {
    const location = await this.locationModel.findById(id);
    if (!location) throw new NotFoundException('位置不存在');

    await this.inventoryModel.deleteMany({ locationId: new Types.ObjectId(id) });
    await this.locationModel.findByIdAndDelete(id);

    await this.historyService.log({
      userId: user._id.toString(),
      userName: user.name,
      action: 'delete',
      entity: 'location',
      description: `删除位置: ${location.code}`,
    });

    return { message: '位置已删除' };
  }
}
