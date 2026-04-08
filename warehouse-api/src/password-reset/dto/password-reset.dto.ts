import { IsString, IsNotEmpty, IsOptional, IsIn, MinLength } from 'class-validator';

export class CreateResetRequestDto {
  @IsString()
  @IsNotEmpty()
  username: string;

  @IsOptional()
  @IsString()
  userNote?: string;
}

export class ResolveResetRequestDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(['completed', 'rejected'])
  status: string;

  @IsOptional()
  @IsString()
  adminNote?: string;

  /** Required when status=completed */
  @IsOptional()
  @IsString()
  @MinLength(6)
  newPassword?: string;
}
