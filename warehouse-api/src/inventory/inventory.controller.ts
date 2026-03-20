import { Controller, Get, Put, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { UpsertInventoryDto } from './dto/inventory.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('inventory')
@UseGuards(JwtAuthGuard, RolesGuard)
export class InventoryController {
  constructor(private inventoryService: InventoryService) {}

  @Get()
  findAll(
    @Query('skuId') skuId?: string,
    @Query('locationId') locationId?: string,
  ) {
    return this.inventoryService.findAll(skuId, locationId);
  }

  @Put()
  @Roles('editor')
  upsert(@Body() dto: UpsertInventoryDto, @CurrentUser() user: any) {
    return this.inventoryService.upsert(dto, user);
  }

  @Delete(':id')
  @Roles('editor')
  remove(@Param('id') id: string, @CurrentUser() user: any) {
    return this.inventoryService.remove(id, user);
  }

  @Delete()
  @Roles('admin')
  clearAll(@CurrentUser() user: any) {
    return this.inventoryService.clearAll(user);
  }
}
