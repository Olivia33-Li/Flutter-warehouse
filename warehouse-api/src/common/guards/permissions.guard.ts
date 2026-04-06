import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSION_KEY } from '../decorators/require-permission.decorator';
import { hasPermission, type Permission } from '../permissions';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<Permission>(PERMISSION_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required) return true;

    const { user } = context.switchToHttp().getRequest();
    if (!user) return false;

    // Prefer the pre-computed permissions[] array attached by JwtStrategy.validate().
    // Fall back to re-deriving from role string if the array is missing.
    const allowed: boolean = Array.isArray(user.permissions)
      ? (user.permissions as string[]).includes(required)
      : hasPermission(user.role, required);

    if (!allowed) {
      throw new ForbiddenException(`权限不足（需要 ${required}）`);
    }
    return true;
  }
}
