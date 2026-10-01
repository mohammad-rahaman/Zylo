import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { User } from '../database/schemas/user.schema';
import { RefreshToken } from '../database/schemas/refresh-token.schema';

describe('AuthService', () => {
  let service: AuthService;
  let userModel: any;
  let refreshTokenModel: any;
  let jwtService: any;

  beforeEach(async () => {
    userModel = {
      findOne: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
    };

    refreshTokenModel = {
      create: jest.fn(),
      findOne: jest.fn(),
      deleteOne: jest.fn(),
      deleteMany: jest.fn(),
    };

    jwtService = {
      sign: jest.fn().mockReturnValue('mock_access_token'),
    };

    const configService = {
      get: jest.fn((key: string, defaultValue?: any) => {
        if (key === 'jwt.accessSecret') return 'test_secret';
        if (key === 'jwt.accessExpiration') return '15m';
        return defaultValue;
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: getModelToken(User.name), useValue: userModel },
        { provide: getModelToken(RefreshToken.name), useValue: refreshTokenModel },
        { provide: JwtService, useValue: jwtService },
        { provide: ConfigService, useValue: configService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('register', () => {
    it('should throw ConflictException if user already exists', async () => {
      userModel.findOne.mockResolvedValue({ email: 'test@zylo.com', username: 'zylo_user' });

      await expect(
        service.register({
          username: 'zylo_user',
          displayName: 'Zylo User',
          email: 'test@zylo.com',
          password: 'Password123!',
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('should register a new user successfully and return tokens', async () => {
      userModel.findOne.mockResolvedValue(null);
      const mockCreatedUser = {
        _id: '507f1f77bcf86cd799439011',
        username: 'newuser',
        displayName: 'New User',
        email: 'newuser@zylo.com',
        profilePhoto: '',
        bio: 'Hey there! I am using Zylo.',
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      userModel.create.mockResolvedValue(mockCreatedUser);
      refreshTokenModel.create.mockResolvedValue({});

      const result = await service.register({
        username: 'newuser',
        displayName: 'New User',
        email: 'newuser@zylo.com',
        password: 'Password123!',
      });

      expect(result).toHaveProperty('accessToken', 'mock_access_token');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.username).toBe('newuser');
    });
  });

  describe('login', () => {
    it('should throw UnauthorizedException if user does not exist', async () => {
      userModel.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(null),
      });

      await expect(
        service.login({
          login: 'nonexistent',
          password: 'password',
        }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should return tokens on valid credentials', async () => {
      const hashedPassword = await bcrypt.hash('CorrectPassword123!', 10);
      const mockUser = {
        _id: '507f1f77bcf86cd799439011',
        username: 'existing',
        displayName: 'Existing User',
        email: 'existing@zylo.com',
        passwordHash: hashedPassword,
        profilePhoto: '',
        bio: 'Hello',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      userModel.findOne.mockReturnValue({
        select: jest.fn().mockResolvedValue(mockUser),
      });
      refreshTokenModel.create.mockResolvedValue({});

      const result = await service.login({
        login: 'existing',
        password: 'CorrectPassword123!',
      });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.user.username).toBe('existing');
    });
  });
});
