import { Injectable, UnauthorizedException, BadRequestException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RefreshTokenDto, ForgotPasswordDto, ResetPasswordDto } from './dto/auth.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private jwtService: JwtService,
  ) {}

  async login(loginDto: LoginDto) {
    const { identifier, password } = loginDto;

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier.trim().toLowerCase() },
          { phone: identifier.trim() },
        ],
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid email/phone or password');
    }

    if (!user.isActive) {
      throw new UnauthorizedException('Your account is deactivated. Contact Admin.');
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid email/phone or password');
    }

    const tokens = await this.generateTokens(user.id, user.email, user.role);

    // Record audit log
    await this.prisma.auditLog.create({
      data: {
        userId: user.id,
        action: 'USER_LOGIN',
        entity: 'User',
        entityId: user.id,
        changesPayload: JSON.stringify({ role: user.role }),
      },
    });

    return {
      message: 'Login successful',
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        avatarUrl: user.avatarUrl,
      },
      ...tokens,
    };
  }

  async refreshToken(dto: RefreshTokenDto) {
    try {
      const payload = this.jwtService.verify(dto.refreshToken, {
        secret: process.env.JWT_REFRESH_SECRET || 'super_secret_refresh_signage_production_key_2026_y88!',
      });

      const user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
      });

      if (!user || !user.isActive) {
        throw new UnauthorizedException('User not found or deactivated');
      }

      return this.generateTokens(user.id, user.email, user.role);
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }
  }

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: dto.emailOrPhone.trim().toLowerCase() },
          { phone: dto.emailOrPhone.trim() },
        ],
      },
    });

    if (!user) {
      // Return safe message
      return { message: 'If the account exists, a reset instruction has been sent.' };
    }

    // Return dummy verification token for development
    return {
      message: 'Password reset code sent successfully.',
      userId: user.id,
    };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.prisma.user.findUnique({
      where: { id: dto.userId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.newPassword, salt);

    await this.prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
    });

    return { message: 'Password has been successfully reset. You can now login.' };
  }

  async getProfile(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        baseSalary: true,
        avatarUrl: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  private async generateTokens(userId: string, email: string, role: string) {
    const payload = { sub: userId, email, role };

    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_SECRET || 'super_secret_jwt_signage_production_key_2026_x99!',
      expiresIn: process.env.JWT_EXPIRES_IN || '1d',
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_REFRESH_SECRET || 'super_secret_refresh_signage_production_key_2026_y88!',
      expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
    });

    return {
      accessToken,
      refreshToken,
      tokenType: 'Bearer',
      expiresIn: process.env.JWT_EXPIRES_IN || '1d',
    };
  }
}
