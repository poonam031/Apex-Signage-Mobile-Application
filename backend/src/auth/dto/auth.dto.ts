import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  @ApiProperty({ example: 'admin@signage.com', description: 'User email or phone' })
  @IsNotEmpty()
  @IsString()
  identifier: string;

  @ApiProperty({ example: 'admin123', description: 'User password' })
  @IsNotEmpty()
  @IsString()
  password: string;
}

export class RefreshTokenDto {
  @ApiProperty({ description: 'JWT Refresh Token' })
  @IsNotEmpty()
  @IsString()
  refreshToken: string;
}

export class ForgotPasswordDto {
  @ApiProperty({ example: 'admin@signage.com' })
  @IsNotEmpty()
  @IsString()
  emailOrPhone: string;
}

export class ResetPasswordDto {
  @ApiProperty()
  @IsNotEmpty()
  @IsString()
  userId: string;

  @ApiProperty({ example: 'newSecretPass123' })
  @IsNotEmpty()
  @IsString()
  newPassword: string;
}
