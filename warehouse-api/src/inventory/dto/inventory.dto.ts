import { IsString, IsNotEmpty, IsNumber, Min } from 'class-validator';

export class UpsertInventoryDto {
  @IsString()
  @IsNotEmpty()
  skuId: string;

  @IsString()
  @IsNotEmpty()
  locationId: string;

  @IsNumber()
  @Min(0)
  quantity: number;
}
