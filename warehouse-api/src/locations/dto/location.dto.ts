import { IsString, IsNotEmpty, IsOptional } from 'class-validator';

export class CreateLocationDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class UpdateLocationDto {
  @IsOptional()
  @IsString()
  description?: string;
}
