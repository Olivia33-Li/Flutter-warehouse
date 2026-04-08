import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { PasswordResetService } from './password-reset.service';
import { CreateResetRequestDto, ResolveResetRequestDto } from './dto/password-reset.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PERM } from '../common/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@Controller('password-reset')
export class PasswordResetController {
  constructor(private service: PasswordResetService) {}

  /** POST /password-reset/request — public, no auth required */
  @Post('request')
  createRequest(@Body() dto: CreateResetRequestDto) {
    return this.service.createRequest(dto);
  }

  /** GET /password-reset — admin only */
  @Get()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermission(PERM.USER_MANAGE)
  findAll(@Query('status') status?: string) {
    return this.service.findAll(status);
  }

  /** PATCH /password-reset/:id/resolve — admin only */
  @Patch(':id/resolve')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermission(PERM.USER_MANAGE)
  resolve(
    @Param('id') id: string,
    @Body() dto: ResolveResetRequestDto,
    @CurrentUser() user: any,
  ) {
    return this.service.resolve(id, dto, user.name ?? user.username);
  }

  /** DELETE /password-reset/:id — admin only */
  @Delete(':id')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermission(PERM.USER_MANAGE)
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}
