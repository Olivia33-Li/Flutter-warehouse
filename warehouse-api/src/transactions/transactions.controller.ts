import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { InventoryService } from '../inventory/inventory.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('transactions')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class TransactionsController {
  constructor(private inventoryService: InventoryService) {}

  @Get()
  @RequirePermission(PERM.INV_VIEW)
  getTransactions(
    @Query('skuCode') skuCode?: string,
    @Query('locationId') locationId?: string,
    @Query('type') type?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.getTransactions({
      skuCode, locationId, type, startDate, endDate,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 20,
    });
  }

  @Post('in')
  @RequirePermission(PERM.INV_STOCK_IN)
  stockIn(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.stockIn(dto, user);
  }

  @Post('out')
  @RequirePermission(PERM.INV_STOCK_OUT)
  stockOut(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.stockOut(dto, user);
  }

  @Post('adjust')
  @RequirePermission(PERM.INV_ADJUST)
  stockAdjust(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.stockAdjust(dto, user);
  }

  @Post('correct-sku')
  @RequirePermission(PERM.INV_ADJUST)
  correctSku(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.correctSku(dto, user);
  }

  @Post('confirm-pending')
  @RequirePermission(PERM.INV_ADJUST)
  confirmPending(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.confirmPending(dto, user);
  }

  @Post('split-pending')
  @RequirePermission(PERM.INV_ADJUST)
  splitPending(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.splitPending(dto, user);
  }
}
