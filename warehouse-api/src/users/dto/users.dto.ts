import { IsString, IsIn, IsNotEmpty, IsOptional, MinLength } from 'class-validator';

export class UpdateRoleDto {
  @IsString()
  @IsIn(['admin', 'supervisor', 'staff'])
  role: 'admin' | 'supervisor' | 'staff';
}

export class ResetPasswordDto {
  @IsString()
  @MinLength(6)
  newPassword: string;
}

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @MinLength(6)
  password: string;

  @IsOptional()
  @IsString()
  @IsIn(['admin', 'supervisor', 'staff'])
  role?: 'admin' | 'supervisor' | 'staff';
}
