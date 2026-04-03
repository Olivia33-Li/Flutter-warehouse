import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { InventoryService } from '../inventory/inventory.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('transactions')
@UseGuards(JwtAuthGuard, RolesGuard)
export class TransactionsController {
  constructor(private inventoryService: InventoryService) {}

  @Post('in')
  @Roles('editor')
  stockIn(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.stockIn(dto, user);
  }

  @Post('out')
  @Roles('editor')
  stockOut(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.stockOut(dto, user);
  }

  @Post('adjust')
  @Roles('editor')
  stockAdjust(@Body() dto: any, @CurrentUser() user: any) {
    return this.inventoryService.stockAdjust(dto, user);
  }
}
