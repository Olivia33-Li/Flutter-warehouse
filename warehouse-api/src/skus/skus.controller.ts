import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { SkusService } from './skus.service';
import { CreateSkuDto, UpdateSkuDto } from './dto/sku.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('skus')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class SkusController {
  constructor(private skusService: SkusService) {}

  @Get()
  @RequirePermission(PERM.SKU_VIEW)
  findAll(
    @Query('search') search?: string,
    @Query('statusFilter') statusFilter?: string,
  ) {
    const filter = (['active', 'archived', 'all'] as const).includes(statusFilter as any)
      ? (statusFilter as 'active' | 'archived' | 'all')
      : 'active';
    return this.skusService.findAll(search, filter);
  }

  // archive/restore BEFORE :id to avoid routing conflict
  @Patch(':id/archive')
  @RequirePermission(PERM.SKU_ARCHIVE)
  archive(@Param('id') id: string, @CurrentUser() user: any) {
    return this.skusService.archive(id, user);
  }

  @Patch(':id/restore')
  @RequirePermission(PERM.SKU_ARCHIVE)
  restore(@Param('id') id: string, @CurrentUser() user: any) {
    return this.skusService.restore(id, user);
  }

  @Get(':id')
  @RequirePermission(PERM.SKU_VIEW)
  findOne(@Param('id') id: string) {
    return this.skusService.findOne(id);
  }

  @Post()
  @RequirePermission(PERM.SKU_WRITE)
  create(@Body() dto: CreateSkuDto, @CurrentUser() user: any) {
    return this.skusService.create(dto, user);
  }

  @Patch(':id')
  @RequirePermission(PERM.SKU_WRITE)
  update(@Param('id') id: string, @Body() dto: UpdateSkuDto, @CurrentUser() user: any) {
    return this.skusService.update(id, dto, user);
  }

  @Delete(':id')
  @RequirePermission(PERM.SKU_DELETE)
  remove(@Param('id') id: string, @CurrentUser() user: any) {
    return this.skusService.remove(id, user);
  }
}
