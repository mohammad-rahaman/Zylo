import {
  Injectable,
  ConflictException,
  UnauthorizedException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import * as crypto from 'crypto';
import { User, UserDocument } from '../database/schemas/user.schema';
import { RefreshToken, RefreshTokenDocument } from '../database/schemas/refresh-token.schema';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @InjectModel(User.name) private userModel: Model<UserDocument>,
    @InjectModel(RefreshToken.name) private refreshTokenModel: Model<RefreshTokenDocument>,
    private jwtService: JwtService,
    private configService: ConfigService,
  ) {}

  private hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private async generateTokens(user: UserDocument) {
    const payload = {
      sub: user._id.toString(),
      username: user.username,
      email: user.email,
    };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.configService.get<string>('jwt.accessSecret'),
      expiresIn: this.configService.get<string>('jwt.accessExpiration', '15m'),
    });

    const refreshTokenRaw = crypto.randomBytes(40).toString('hex');
    const tokenHash = this.hashToken(refreshTokenRaw);

    // Refresh token expiry calculation (e.g. 7 days)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    await this.refreshTokenModel.create({
      userId: user._id,
      tokenHash,
      expiresAt,
    });

    return {
      accessToken,
      refreshToken: refreshTokenRaw,
      user: {
        id: user._id.toString(),
        username: user.username,
        displayName: user.displayName,
        email: user.email,
        profilePhoto: user.profilePhoto,
        bio: user.bio,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      },
    };
  }

  async register(dto: RegisterDto) {
    const existingUser = await this.userModel.findOne({
      $or: [
        { email: dto.email.toLowerCase().trim() },
        { username: dto.username.toLowerCase().trim() },
      ],
    });

    if (existingUser) {
      if (existingUser.email === dto.email.toLowerCase().trim()) {
        throw new ConflictException('Email is already registered');
      }
      throw new ConflictException('Username is already taken');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(dto.password, salt);

    const newUser = await this.userModel.create({
      username: dto.username.toLowerCase().trim(),
      displayName: dto.displayName.trim(),
      email: dto.email.toLowerCase().trim(),
      passwordHash,
      profilePhoto: '',
      bio: 'Hey there! I am using Zylo.',
      isOnline: false,
      lastSeen: new Date(),
    });

    return this.generateTokens(newUser);
  }

  async login(dto: LoginDto) {
    const query = dto.login.toLowerCase().trim();
    const user = await this.userModel
      .findOne({
        $or: [{ email: query }, { username: query }],
      })
      .select('+passwordHash');

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    return this.generateTokens(user);
  }

  async refresh(refreshTokenRaw: string) {
    if (!refreshTokenRaw) {
      throw new BadRequestException('Refresh token is required');
    }

    const tokenHash = this.hashToken(refreshTokenRaw);
    const storedToken = await this.refreshTokenModel.findOne({ tokenHash });

    if (!storedToken) {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    if (new Date() > storedToken.expiresAt) {
      await this.refreshTokenModel.deleteOne({ _id: storedToken._id });
      throw new UnauthorizedException('Refresh token has expired');
    }

    const user = await this.userModel.findById(storedToken.userId);
    if (!user) {
      await this.refreshTokenModel.deleteOne({ _id: storedToken._id });
      throw new UnauthorizedException('User no longer exists');
    }

    // Refresh token rotation: delete old token before generating new one
    await this.refreshTokenModel.deleteOne({ _id: storedToken._id });

    return this.generateTokens(user);
  }

  async logout(userId: string, refreshTokenRaw?: string) {
    if (refreshTokenRaw) {
      const tokenHash = this.hashToken(refreshTokenRaw);
      await this.refreshTokenModel.deleteOne({ tokenHash });
    } else if (userId) {
      await this.refreshTokenModel.deleteMany({ userId: new Types.ObjectId(userId) });
    }
    return { success: true, message: 'Logged out successfully' };
  }
}
