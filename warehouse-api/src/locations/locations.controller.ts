import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { LocationsService } from './locations.service';
import { CreateLocationDto, UpdateLocationDto } from './dto/location.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('locations')
@UseGuards(JwtAuthGuard, RolesGuard)
export class LocationsController {
  constructor(private locationsService: LocationsService) {}

  @Get()
  findAll(@Query('search') search?: string) {
    return this.locationsService.findAll(search);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.locationsService.findOne(id);
  }

  @Post()
  @Roles('editor')
  create(@Body() dto: CreateLocationDto, @CurrentUser() user: any) {
    return this.locationsService.create(dto, user);
  }

  @Patch(':id')
  @Roles('editor')
  update(@Param('id') id: string, @Body() dto: UpdateLocationDto, @CurrentUser() user: any) {
    return this.locationsService.update(id, dto, user);
  }

  @Delete(':id')
  @Roles('editor')
  remove(@Param('id') id: string, @CurrentUser() user: any) {
    return this.locationsService.remove(id, user);
  }
}
