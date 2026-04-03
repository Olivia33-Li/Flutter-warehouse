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
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

const FILE_OPTIONS = { limits: { fileSize: 10 * 1024 * 1024 } };

@Controller('import')
@UseGuards(JwtAuthGuard, RolesGuard)
export class ImportController {
  constructor(private importService: ImportService) {}

  // ─── Validate (dry run) ───────────────────────────────────────────────────────

  @Post('skus/validate')
  @Roles('editor')
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateSkus(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.validateSkus(file.buffer, file.originalname);
  }

  @Post('locations/validate')
  @Roles('editor')
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateLocations(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.validateLocations(file.buffer, file.originalname);
  }

  @Post('inventory/validate')
  @Roles('editor')
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  validateInventory(@UploadedFile() file: Express.Multer.File) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.validateInventory(file.buffer, file.originalname);
  }

  // ─── Import ───────────────────────────────────────────────────────────────────

  @Post('skus')
  @Roles('editor')
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importSkus(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.importSkus(file.buffer, file.originalname, user);
  }

  @Post('locations')
  @Roles('editor')
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importLocations(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.importLocations(file.buffer, file.originalname, user);
  }

  @Post('inventory')
  @Roles('editor')
  @UseInterceptors(FileInterceptor('file', FILE_OPTIONS))
  importInventory(@UploadedFile() file: Express.Multer.File, @CurrentUser() user: any) {
    if (!file) throw new BadRequestException('请上传 CSV 文件');
    return this.importService.importInventory(file.buffer, file.originalname, user);
  }

  // ─── Logs ─────────────────────────────────────────────────────────────────────

  @Get('logs')
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

  @Get('logs/:id/export')
  async exportLog(@Param('id') id: string, @Res() res: Response) {
    const buffer = await this.importService.exportLog(id);
    res.set({
      'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'Content-Disposition': `attachment; filename="import_log_${id}.xlsx"`,
    });
    res.send(buffer);
  }
}
