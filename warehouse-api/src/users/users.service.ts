import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import * as bcrypt from 'bcrypt';
import { User, UserDocument } from '../schemas/user.schema';
import { UpdateRoleDto, ResetPasswordDto } from './dto/users.dto';

@Injectable()
export class UsersService {
  constructor(@InjectModel(User.name) private userModel: Model<UserDocument>) {}

  async findAll() {
    return this.userModel.find().select('-passwordHash').lean();
  }

  async updateRole(id: string, dto: UpdateRoleDto, currentUserId: string) {
    const user = await this.userModel.findById(id);
    if (!user) throw new NotFoundException('用户不存在');

    if (user.role === 'admin' && dto.role !== 'admin') {
      const adminCount = await this.userModel.countDocuments({ role: 'admin' });
      if (adminCount <= 1) throw new BadRequestException('至少需要保留一个管理员');
    }

    user.role = dto.role;
    await user.save();
    return { message: '角色更新成功' };
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

    if (user.role === 'admin') {
      const adminCount = await this.userModel.countDocuments({ role: 'admin' });
      if (adminCount <= 1) throw new BadRequestException('至少需要保留一个管理员');
    }

    await this.userModel.findByIdAndDelete(id);
    return { message: '用户已删除' };
  }
}
