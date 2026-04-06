import { Controller, Get, Post, Patch, Put, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('inventory')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class InventoryController {
  constructor(private inventoryService: InventoryService) {}

  @Get()
  @RequirePermission(PERM.INV_VIEW)
  findAll(
    @Query('skuCode') skuCode?: string,
    @Query('locationId') locationId?: string,
    @Query('pendingOnly') pendingOnly?: string,
    @Query('stockStatus') stockStatus?: string,
  ) {
    return this.inventoryService.findAll({ skuCode, locationId, pendingOnly: pendingOnly === 'true', stockStatus });
  }

  @Post()
  @RequirePermission(PERM.INV_WRITE)
  create(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.create(dto, user);
  }

  @Patch(':id')
  @RequirePermission(PERM.INV_WRITE)
  update(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.update(id, dto, user);
  }

  // HIGH_RISK: must be declared before :id
  @Delete('all-data')
  @RequirePermission(PERM.HIGH_RISK)
  clearAllData(@CurrentUser() user: any) {
    return this.inventoryService.clearAllData(user);
  }

  @Delete(':id')
  @RequirePermission(PERM.INV_DELETE)
  remove(@Param('id') id: string, @CurrentUser() user: any) {
    return this.inventoryService.remove(id, user);
  }

  @Delete()
  @RequirePermission(PERM.HIGH_RISK)
  clearAll(@CurrentUser() user: any) {
    return this.inventoryService.clearAll(user);
  }

  @Put()
  @RequirePermission(PERM.INV_WRITE)
  upsert(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.upsert(dto, user);
  }
}
