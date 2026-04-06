import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { HistoryService } from './history.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { normalizeRole } from '../common/permissions';

@Controller('audit-logs')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class HistoryController {
  constructor(private historyService: HistoryService) {}

  // Map frontend type filter (IN/OUT/ADJUST/TRANSFER) → business action strings stored in DB
  private static readonly TYPE_TO_ACTIONS: Record<string, string[]> = {
    IN:       ['入库', '录入', '暂存'],
    OUT:      ['出库'],
    ADJUST:   ['调整', '结构修改', 'SKU更正', 'SKU更正并合并', '暂存转正式', '暂存拆分'],
    TRANSFER: ['批量转移', '批量复制'],
  };

  @Get()
  findAll(
    @CurrentUser() currentUser: any,
    @Query('userId') userId?: string,
    @Query('action') action?: string,
    @Query('entity') entity?: string,
    @Query('keyword') keyword?: string,
    @Query('businessAction') businessAction?: string,
    @Query('type') type?: string,
    @Query('skuCode') skuCode?: string,
    @Query('locationCode') locationCode?: string,
    @Query('startDate') startDate?: string,
    @Query('endDate') endDate?: string,
    @Query('userName') userName?: string,
    @Query('inventoryChangingOnly') inventoryChangingOnly?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    const role = normalizeRole(currentUser.role);

    // staff can only see their own records
    const effectiveUserId = role === 'staff'
      ? currentUser._id.toString()
      : userId;

    // Map type → businessActions array for OR-match
    const businessActions = type
      ? (HistoryController.TYPE_TO_ACTIONS[type.toUpperCase()] ?? [type])
      : undefined;

    return this.historyService.findAll({
      userId: effectiveUserId,
      action, entity, keyword, businessAction, businessActions,
      locationCode, skuCode, startDate, endDate, userName,
      inventoryChangingOnly: inventoryChangingOnly === 'true',
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 50,
    });
  }
}
