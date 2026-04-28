import { IsString, IsNotEmpty, MinLength, MaxLength, Matches } from 'class-validator';

export class RegisterDto {
  @IsString()
  @MinLength(6, { message: '用户名至少6位' })
  @MaxLength(20, { message: '用户名最多20位' })
  @Matches(/^(?=.*[a-z])[a-z0-9]+$/, { message: '用户名只能包含小写字母和数字，且至少含一个小写字母' })
  username: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @MinLength(6, { message: '密码至少6位' })
  @MaxLength(20, { message: '密码最多20位' })
  @Matches(/^(?=.*[a-z])(?=.*[0-9])[a-z0-9]+$/, { message: '密码只能包含小写字母和数字，且至少含一个小写字母和一个数字' })
  password: string;
}

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsString()
  @IsNotEmpty()
  password: string;
}

export class ChangePasswordDto {
  @IsString()
  @IsNotEmpty()
  oldPassword: string;

  @IsString()
  @MinLength(6, { message: '密码至少6位' })
  @MaxLength(20, { message: '密码最多20位' })
  @Matches(/^(?=.*[a-z])(?=.*[0-9])[a-z0-9]+$/, { message: '密码只能包含小写字母和数字，且至少含一个小写字母和一个数字' })
  newPassword: string;
}

export class UpdateProfileDto {
  @IsString()
  @IsNotEmpty()
  name: string;
}

export class RefreshTokenDto {
  @IsString()
  @IsNotEmpty()
  refreshToken: string;
}
