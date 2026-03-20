import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { SkusService } from './skus.service';
import { CreateSkuDto, UpdateSkuDto } from './dto/sku.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('skus')
@UseGuards(JwtAuthGuard, RolesGuard)
export class SkusController {
  constructor(private skusService: SkusService) {}

  @Get()
  findAll(@Query('search') search?: string) {
    return this.skusService.findAll(search);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.skusService.findOne(id);
  }

  @Post()
  @Roles('editor')
  create(@Body() dto: CreateSkuDto, @CurrentUser() user: any) {
    return this.skusService.create(dto, user);
  }

  @Patch(':id')
  @Roles('editor')
  update(@Param('id') id: string, @Body() dto: UpdateSkuDto, @CurrentUser() user: any) {
    return this.skusService.update(id, dto, user);
  }

  @Delete(':id')
  @Roles('editor')
  remove(@Param('id') id: string, @CurrentUser() user: any) {
    return this.skusService.remove(id, user);
  }
}
