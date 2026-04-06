import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from '../schemas/user.schema';
import { UpdateRoleDto, ResetPasswordDto, CreateUserDto } from './dto/users.dto';
import { normalizeRole, ROLE_LABEL } from '../common/permissions';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async findAll() {
    const users = await this.userModel.find().select('-passwordHash').sort({ createdAt: -1 }).lean();
    return users.map((u) => this._format(u));
  }

  async create(dto: CreateUserDto) {
    const exists = await this.userModel.findOne({ username: dto.username.toLowerCase() });
    if (exists) throw new ConflictException('用户名已存在');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.userModel.create({
      username: dto.username.toLowerCase(),
      name: dto.name,
      passwordHash,
      role: dto.role ?? 'staff',
      isActive: true,
    });

    return this._format(user.toObject());
  }

  async updateRole(id: string, dto: UpdateRoleDto, currentUserId: string) {
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('用户不存在');

    const currentRole = normalizeRole(user.role);
    if (currentRole === 'admin' && dto.role !== 'admin') {
      const adminCount = await this.userModel.countDocuments({
        $or: [{ role: 'admin' }],
      });
      if (adminCount <= 1) throw new BadRequestException('至少需要保留一个管理员');
    }

    user.role = dto.role;
    await user.save();
    return { message: '角色更新成功', role: dto.role, roleLabel: ROLE_LABEL[dto.role] };
  }

  async disable(id: string, currentUserId: string) {
    if (id === currentUserId) throw new ForbiddenException('不能停用自己的账号');
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('用户不存在');
    if (normalizeRole(user.role) === 'admin') {
      const adminCount = await this.userModel.countDocuments({
        $or: [{ role: 'admin' }],
        isActive: { $ne: false },
      });
      if (adminCount <= 1) throw new BadRequestException('至少需要保留一个启用的管理员');
    }
    user.isActive = false;
    await user.save();
    return { message: '账号已停用' };
  }

  async enable(id: string) {
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('用户不存在');
    user.isActive = true;
    await user.save();
    return { message: '账号已启用' };
  }

  async resetPassword(id: string, dto: ResetPasswordDto) {
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('用户不存在');
    user.passwordHash = await bcrypt.hash(dto.newPassword, 10);
    await user.save();
    return { message: '密码重置成功' };
  }

  async remove(id: string, currentUserId: string) {
    if (id === currentUserId) throw new ForbiddenException('不能删除自己');
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('用户不存在');
    if (normalizeRole(user.role) === 'admin') {
      const adminCount = await this.userModel.countDocuments({ $or: [{ role: 'admin' }] });
      if (adminCount <= 1) throw new BadRequestException('至少需要保留一个管理员');
    }
    await this.userModel.findByIdAndDelete(id);
    return { message: '用户已删除' };
  }

  private _format(u: any) {
    const role = normalizeRole(u.role);
    return {
      _id: u._id,
      username: u.username,
      name: u.name,
      role,
      roleLabel: ROLE_LABEL[role],
      isActive: u.isActive !== false,
      lastLoginAt: u.lastLoginAt ?? null,
      createdAt: u.createdAt,
    };
  }
}
