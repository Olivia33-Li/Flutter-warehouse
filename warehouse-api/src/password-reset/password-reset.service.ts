import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { PasswordResetRequest, PasswordResetRequestDocument } from '../schemas/password-reset-request.schema';
import { User, UserDocument } from '../schemas/user.schema';
import { CreateResetRequestDto, ResolveResetRequestDto } from './dto/password-reset.dto';

@Injectable()
export class PasswordResetService {
  constructor(
    @InjectModel(PasswordResetRequest.name)
    private resetModel: Model<PasswordResetRequestDocument>,
    @InjectModel(User.name)
    private userModel: Model<UserDocument>,
  ) {}

  /** Public: user submits a reset request (no auth required) */
  async createRequest(dto: CreateResetRequestDto) {
    const user = await this.userModel.findOne({ username: dto.username.toLowerCase() });
    if (!user) throw new NotFoundException('用户名不存在，请确认后重试');

    // Allow one pending request per user at a time
    const existing = await this.resetModel.findOne({
      username: dto.username.toLowerCase(),
      status: 'pending',
    });
    if (existing) {
      return { message: '已有待处理的申请，请等待管理员处理' };
    }

    await this.resetModel.create({
      username: user.username,
      displayName: user.name,
      userNote: dto.userNote ?? '',
      status: 'pending',
    });

    return { message: '申请已提交，请联系管理员处理' };
  }

  /** Admin: list all requests */
  async findAll(status?: string) {
    const filter: any = {};
    if (status) filter.status = status;
    return this.resetModel.find(filter).sort({ createdAt: -1 }).lean();
  }

  /** Admin: resolve a request (complete or reject) */
  async resolve(id: string, dto: ResolveResetRequestDto, adminName: string) {
    const req = await this.resetModel.findById(id);
    if (!req) throw new NotFoundException('申请记录不存在');
    if (req.status !== 'pending') {
      throw new BadRequestException('该申请已处理，无法重复操作');
    }

    if (dto.status === 'completed') {
      if (!dto.newPassword || dto.newPassword.length < 6) {
        throw new BadRequestException('重置密码不能少于 6 位');
      }
      const user = await this.userModel.findOne({ username: req.username });
      if (!user) throw new NotFoundException('对应用户不存在');

      user.passwordHash = await bcrypt.hash(dto.newPassword, 10);
      user.mustChangePassword = true;
      await user.save();
    }

    req.status = dto.status;
    req.adminNote = dto.adminNote ?? '';
    req.resolvedAt = new Date();
    req.resolvedBy = adminName;
    await req.save();

    return { message: dto.status === 'completed' ? '密码已重置，用户下次登录时必须修改密码' : '申请已拒绝' };
  }

  /** Admin: delete a request record */
  async remove(id: string) {
    await this.resetModel.findByIdAndDelete(id);
    return { message: '记录已删除' };
  }
}
