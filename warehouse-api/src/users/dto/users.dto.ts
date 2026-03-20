import { IsString, IsIn } from 'class-validator';
import type { UserRole } from '../../schemas/user.schema';

export class UpdateRoleDto {
  @IsString()
  @IsIn(['admin', 'editor', 'viewer'])
  role: UserRole;
}

export class ResetPasswordDto {
  @IsString()
  newPassword: string;
}
