import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { NotFoundException } from '@nestjs/common';
import { UsersService } from './users.service';
import { User } from '../database/schemas/user.schema';
import { BlockedUser } from '../database/schemas/blocked-user.schema';
import { RedisService } from '../redis/redis.service';

describe('UsersService', () => {
  let service: UsersService;
  let userModel: any;
  let blockedUserModel: any;
  let redisService: any;

  beforeEach(async () => {
    userModel = {
      find: jest.fn(),
      findById: jest.fn(),
      findByIdAndUpdate: jest.fn(),
    };

    blockedUserModel = {
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn(),
      deleteOne: jest.fn(),
    };

    redisService = {
      getUserPresence: jest.fn().mockResolvedValue({ isOnline: true }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getModelToken(User.name), useValue: userModel },
        { provide: getModelToken(BlockedUser.name), useValue: blockedUserModel },
        { provide: RedisService, useValue: redisService },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('getUserById', () => {
    it('should throw NotFoundException if user does not exist', async () => {
      userModel.findById.mockReturnValue({
        select: jest.fn().mockReturnValue({
          lean: jest.fn().mockResolvedValue(null),
        }),
      });

      await expect(
        service.getUserById('507f1f77bcf86cd799439011'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should return user with presence information', async () => {
      const mockUser = {
        _id: '507f1f77bcf86cd799439011',
        username: 'alice',
        displayName: 'Alice',
        email: 'alice@zylo.com',
        profilePhoto: '',
        bio: 'Hello',
        isOnline: false,
        lastSeen: new Date(),
      };

      userModel.findById.mockReturnValue({
        select: jest.fn().mockReturnValue({
          lean: jest.fn().mockResolvedValue(mockUser),
        }),
      });

      const result = await service.getUserById('507f1f77bcf86cd799439011');
      expect(result.id).toBe('507f1f77bcf86cd799439011');
      expect(result.isOnline).toBe(true); // from redis
    });
  });
});
