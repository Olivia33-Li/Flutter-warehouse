import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { LocationsService } from './locations.service';
import { CreateLocationDto, UpdateLocationDto } from './dto/location.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('locations')
@UseGuards(JwtAuthGuard, PermissionsGuard)
export class LocationsController {
  constructor(private locationsService: LocationsService) {}

  @Get()
  @RequirePermission(PERM.LOC_VIEW)
  findAll(@Query('search') search?: string) {
    return this.locationsService.findAll(search);
  }

  @Get(':id')
  @RequirePermission(PERM.LOC_VIEW)
  findOne(@Param('id') id: string) {
    return this.locationsService.findOne(id);
  }

  @Post()
  @RequirePermission(PERM.LOC_WRITE)
  create(@Body() dto: CreateLocationDto, @CurrentUser() user: any) {
    return this.locationsService.create(dto, user);
  }

  @Patch(':id')
  @RequirePermission(PERM.LOC_WRITE)
  update(@Param('id') id: string, @Body() dto: UpdateLocationDto, @CurrentUser() user: any) {
    return this.locationsService.update(id, dto, user);
  }

  @Patch(':id/check')
  @RequirePermission(PERM.LOC_WRITE)
  check(@Param('id') id: string, @Body() dto: { checked: boolean }, @CurrentUser() user: any) {
    return this.locationsService.check(id, dto.checked, user);
  }

  @Post(':id/transfer')
  @RequirePermission(PERM.INV_TRANSFER)
  transfer(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: any) {
    return this.locationsService.transfer(id, dto, user);
  }

  @Post(':id/copy')
  @RequirePermission(PERM.INV_WRITE)
  copy(@Param('id') id: string, @Body() dto: any, @CurrentUser() user: any) {
    return this.locationsService.copy(id, dto, user);
  }

  @Delete(':id')
  @RequirePermission(PERM.LOC_DELETE)
  remove(@Param('id') id: string, @CurrentUser() user: any) {
    return this.locationsService.remove(id, user);
  }
}
