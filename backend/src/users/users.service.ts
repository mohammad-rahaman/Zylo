import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { User, UserDocument } from '../database/schemas/user.schema';
import { BlockedUser, BlockedUserDocument } from '../database/schemas/blocked-user.schema';
import { RedisService } from '../redis/redis.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(BlockedUser.name) private blockedUserModel: Model<BlockedUserDocument>,
    private redisService: RedisService,
  ) {}

  async searchUsers(query: string, currentUserId: string) {
    if (!query || query.trim().length === 0) {
      // Return recent active users if query is empty
      const users = await this.userModel
        .find({ _id: { $ne: new Types.ObjectId(currentUserId) } })
        .limit(20)
        .select('username displayName email profilePhoto bio isOnline lastSeen')
        .lean();
      return users;
    }

    const cleanQuery = query.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const regex = new RegExp(cleanQuery, 'i');

    // Get blocked user IDs to filter out
    const blockedRecords = await this.blockedUserModel
      .find({
        $or: [
          { userId: new Types.ObjectId(currentUserId) },
          { blockedUserId: new Types.ObjectId(currentUserId) },
        ],
      })
      .lean();

    const excludedIds = new Set(
      blockedRecords.flatMap((b) => [b.userId.toString(), b.blockedUserId.toString()]),
    );
    excludedIds.add(currentUserId);

    const users = await this.userModel
      .find({
        _id: { $nin: Array.from(excludedIds).map((id) => new Types.ObjectId(id)) },
        $or: [{ username: regex }, { displayName: regex }, { email: regex }],
      })
      .limit(30)
      .select('username displayName email profilePhoto bio isOnline lastSeen')
      .lean();

    return users;
  }

  async getUserById(id: string, currentUserId?: string) {
    if (!Types.ObjectId.isValid(id)) {
      throw new BadRequestException('Invalid user ID');
    }

    const user = await this.userModel
      .findById(id)
      .select('username displayName email profilePhoto bio isOnline lastSeen')
      .lean();

    if (!user) {
      throw new NotFoundException('User not found');
    }

    let isBlocked = false;
    if (currentUserId && currentUserId !== id) {
      const block = await this.blockedUserModel.findOne({
        userId: new Types.ObjectId(currentUserId),
        blockedUserId: new Types.ObjectId(id),
      });
      isBlocked = !!block;
    }

    // Dynamic presence lookup from Redis
    const presence = await this.redisService.getUserPresence(id);

    return {
      ...user,
      id: user._id.toString(),
      isOnline: presence.isOnline ?? user.isOnline,
      lastSeen: presence.lastSeen ?? user.lastSeen,
      isBlocked,
    };
  }

  async updateMe(userId: string, dto: UpdateUserDto) {
    const updated = await this.userModel
      .findByIdAndUpdate(
        userId,
        { $set: dto },
        { new: true, runValidators: true },
      )
      .select('username displayName email profilePhoto bio isOnline lastSeen')
      .lean();

    if (!updated) {
      throw new NotFoundException('User not found');
    }

    return {
      ...updated,
      id: updated._id.toString(),
    };
  }

  async blockUser(currentUserId: string, targetUserId: string) {
    if (currentUserId === targetUserId) {
      throw new BadRequestException('You cannot block yourself');
    }

    if (!Types.ObjectId.isValid(targetUserId)) {
      throw new BadRequestException('Invalid user ID');
    }

    const targetUser = await this.userModel.findById(targetUserId);
    if (!targetUser) {
      throw new NotFoundException('Target user not found');
    }

    try {
      await this.blockedUserModel.create({
        userId: new Types.ObjectId(currentUserId),
        blockedUserId: new Types.ObjectId(targetUserId),
      });
    } catch (e) {
      if (e.code === 11000) {
        throw new ConflictException('User is already blocked');
      }
      throw e;
    }

    return { success: true, message: 'User blocked successfully' };
  }

  async unblockUser(currentUserId: string, targetUserId: string) {
    if (!Types.ObjectId.isValid(targetUserId)) {
      throw new BadRequestException('Invalid user ID');
    }

    const result = await this.blockedUserModel.deleteOne({
      userId: new Types.ObjectId(currentUserId),
      blockedUserId: new Types.ObjectId(targetUserId),
    });

    if (result.deletedCount === 0) {
      throw new NotFoundException('User was not blocked');
    }

    return { success: true, message: 'User unblocked successfully' };
  }

  async isUserBlocked(userA: string, userB: string): Promise<boolean> {
    const block = await this.blockedUserModel.findOne({
      $or: [
        { userId: new Types.ObjectId(userA), blockedUserId: new Types.ObjectId(userB) },
        { userId: new Types.ObjectId(userB), blockedUserId: new Types.ObjectId(userA) },
      ],
    });
    return !!block;
  }
}
