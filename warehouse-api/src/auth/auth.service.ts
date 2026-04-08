import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from '../schemas/user.schema';
import { RegisterDto, LoginDto, ChangePasswordDto, UpdateProfileDto } from './dto/auth.dto';
import { normalizeRole, ROLE_LABEL } from '../common/permissions';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const exists = await this.userModel.findOne({ username: dto.username.toLowerCase() });
    if (exists) throw new ConflictException('用户名已存在');

    // First user becomes admin; subsequent self-registrations become staff
    const count = await this.userModel.countDocuments();
    const role = count === 0 ? 'admin' : 'staff';

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.userModel.create({
      username: dto.username.toLowerCase(),
      name: dto.name,
      passwordHash,
      role,
      isActive: true,
      lastLoginAt: new Date(),
    });

    return this.generateTokens(user);
  }

  async login(dto: LoginDto) {
    const user = await this.userModel.findOne({ username: dto.username.toLowerCase() });
    if (!user) throw new UnauthorizedException('用户名或密码错误');
    if (user.isActive === false) throw new UnauthorizedException('账号已被停用，请联系管理员');

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) throw new UnauthorizedException('用户名或密码错误');

    user.lastLoginAt = new Date();
    await user.save();

    return this.generateTokens(user);
  }

  async refresh(refreshToken: string) {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      });
      const user = await this.userModel.findById(payload.sub);
      if (!user) throw new UnauthorizedException();
      if (user.isActive === false) throw new UnauthorizedException('账号已被停用');
      return this.generateTokens(user);
    } catch {
      throw new UnauthorizedException('Refresh token 无效或已过期');
    }
  }

  async changePassword(userId: string, dto: ChangePasswordDto) {
    const user = await this.userModel.findById(userId);
    if (!user) throw new UnauthorizedException();

    const valid = await bcrypt.compare(dto.oldPassword, user.passwordHash);
    if (!valid) throw new BadRequestException('原密码错误');

    user.passwordHash = await bcrypt.hash(dto.newPassword, 10);
    user.mustChangePassword = false;
    await user.save();
    return { message: '密码修改成功' };
  }

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const user = await this.userModel.findByIdAndUpdate(
      userId,
      { name: dto.name },
      { new: true },
    );
    if (!user) throw new UnauthorizedException();
    const role = normalizeRole(user.role);
    return {
      id: user._id,
      username: user.username,
      name: user.name,
      role,
      roleLabel: ROLE_LABEL[role],
      isActive: user.isActive,
    };
  }

  private generateTokens(user: UserDocument) {
    const role = normalizeRole(user.role);
    const payload = { sub: user._id.toString(), username: user.username, role };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_SECRET'),
      expiresIn: (this.configService.get('JWT_EXPIRES_IN') ?? '15m') as any,
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('JWT_REFRESH_SECRET'),
      expiresIn: (this.configService.get('JWT_REFRESH_EXPIRES_IN') ?? '7d') as any,
    });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        username: user.username,
        name: user.name,
        role,
        roleLabel: ROLE_LABEL[role],
        isActive: user.isActive !== false,
        lastLoginAt: user.lastLoginAt,
        mustChangePassword: user.mustChangePassword === true,
      },
    };
  }
}
