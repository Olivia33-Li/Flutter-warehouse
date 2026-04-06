import { Controller, Get, Res, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { ExportService } from './export.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';

@Controller('export')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ExportController {
  constructor(private exportService: ExportService) {}

  @Get('excel')
  @RequirePermission(PERM.DATA_EXPORT)
  async exportExcel(@Res() res: Response) {
    console.log('[ExportController] GET /api/export/excel');
    try {
      const now = new Date();
      const dateStr =
        `${now.getFullYear()}` +
        `${String(now.getMonth() + 1).padStart(2, '0')}` +
        `${String(now.getDate()).padStart(2, '0')}`;
      const filename = `warehouse_${dateStr}.xlsx`;

      const buffer = await this.exportService.exportAllToExcel();

      res.set({
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="${filename}"`,
        'Content-Length': buffer.length,
      });

      console.log(`[ExportController] success, filename=${filename}, bytes=${buffer.length}`);
      res.send(buffer);
    } catch (e) {
      console.error('[ExportController] exportExcel failed:', e);
      throw e;
    }
  }
}
