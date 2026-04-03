import { Controller, Get, Post, Patch, Put, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { InventoryService } from './inventory.service';
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
    @Query('skuCode') skuCode?: string,
    @Query('locationId') locationId?: string,
    @Query('pendingOnly') pendingOnly?: string,
    @Query('stockStatus') stockStatus?: string,
  ) {
    return this.inventoryService.findAll({
      skuCode,
      locationId,
      pendingOnly: pendingOnly === 'true',
      stockStatus,
    });
  }

  @Post()
  @Roles('editor')
  create(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.create(dto, user);
  }

  @Patch(':id')
  @Roles('editor')
  update(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.update(id, dto, user);
  }

  @Delete('all-data')
  @Roles('admin')
  clearAllData(@CurrentUser() user: any) {
    return this.inventoryService.clearAllData(user);
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

  // Legacy PUT (kept for backward compat)
  @Put()
  @Roles('editor')
  upsert(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.upsert(dto, user);
  }
}
