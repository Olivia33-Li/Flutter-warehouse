import {
  Controller,
  Post,
  Get,
  Param,
  Query,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { ImportService } from './import.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';

const FILE_OPTIONS = { limits: { fileSize: 10 * 1024 * 1024 } };

@Controller('import')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class ImportController {
  constructor(private importService: ImportService) {}

  // ─── Validate (dry run) ───────────────────────────────────────────────────────

  @Post('skus/validate')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateSkus(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.validateSkus(file.buffer, file.originalname);
  }

  @Post('locations/validate')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateLocations(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.validateLocations(file.buffer, file.originalname);
  }

  @Post('inventory/validate')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateInventory(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.validateInventory(file.buffer, file.originalname);
  }

  // ─── Import ───────────────────────────────────────────────────────────────────

  @Post('skus')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importSkus(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.importSkus(file.buffer, file.originalname, user);
  }

  @Post('locations')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importLocations(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.importLocations(file.buffer, file.originalname, user);
  }

  @Post('inventory')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importInventory(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.importInventory(file.buffer, file.originalname, user);
  }

  // ─── SKU barcode update ───────────────────────────────────────────────────────

  @Post('sku-barcode-update/validate')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateSkuBarcodeUpdate(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传文件');
    return this.importService.validateSkuBarcodeUpdate(file.buffer, file.originalname);
  }

  @Post('sku-barcode-update')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importSkuBarcodeUpdate(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传文件');
    return this.importService.importSkuBarcodeUpdate(file.buffer, file.originalname, user);
  }

  // ─── SKU carton qty update ────────────────────────────────────────────────────

  @Post('sku-carton-qty-update/validate')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateSkuCartonQtyUpdate(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传文件');
    return this.importService.validateSkuCartonQtyUpdate(file.buffer, file.originalname);
  }

  @Post('sku-carton-qty-update')
  @RequirePermission(PERM.DATA_IMPORT)
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importSkuCartonQtyUpdate(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传文件');
    return this.importService.importSkuCartonQtyUpdate(file.buffer, file.originalname, user);
  }

  // ─── Logs ─────────────────────────────────────────────────────────────────────

  // Export must be declared BEFORE the list route to avoid NestJS routing conflicts
  @Get('logs/:id/export')
  @RequirePermission(PERM.DATA_IMPORT)
  async exportLog(@Param('id') id: string, @Res() res: Response) {
    console.log(`[Controller] GET /api/import/logs/${id}/export`);
    try {
      const buffer = await this.importService.exportLog(id);
      res.set({
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="import_log_${id}.xlsx"`,
        'Content-Length': buffer.length,
      });
      console.log(`[Controller] exportLog success, bytes=${buffer.length}`);
      res.send(buffer);
    } catch (e) {
      console.error(`[Controller] exportLog failed: ${e}`);
      throw e;
    }
  }

  @Get('logs')
  @RequirePermission(PERM.DATA_IMPORT)
  getLogs(
    @Query('importType') importType?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.importService.getLogs({
      importType,
      page: page ? parseInt(page) : 1,
      limit: limit ? parseInt(limit) : 30,
    });
  }
}
