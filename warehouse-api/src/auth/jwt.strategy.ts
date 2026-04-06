import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { ConfigService } from '@nestjs/config';
import { User, UserDocument } from '../schemas/user.schema';
import { normalizeRole, getRolePermissions } from '../common/permissions';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    configService: ConfigService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET') ?? 'fallback',
    });
  }

  async validate(payload: { sub: string; username: string; role: string }) {
    const user = await this.userModel.findById(payload.sub).select('-passwordHash').lean();
    if (!user) throw new UnauthorizedException('用户不存在');
    if (user.isActive === false) throw new UnauthorizedException('账号已被停用，请联系管理员');

    // Attach normalised role and permissions to the request user object
    const normalizedRole = normalizeRole(user.role);
    return {
      ...user,
      role: normalizedRole,
      permissions: getRolePermissions(normalizedRole),
    };
  }
}
