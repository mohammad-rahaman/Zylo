import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis;
  private subscriber: Redis;
  private isConnected = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const host = this.configService.get<string>('redis.host', 'localhost');
    const port = this.configService.get<number>('redis.port', 6379);
    const password = this.configService.get<string>('redis.password');

    const redisOptions = {
      host,
      port,
      password: password || undefined,
      retryStrategy: (times: number) => {
        if (times > 5) {
          this.logger.warn('Redis reconnection failed after 5 attempts. Falling back to in-memory presence.');
          return null; // stop retrying
        }
        return Math.min(times * 500, 2000);
      },
      lazyConnect: true,
    };

    this.client = new Redis(redisOptions);
    this.subscriber = new Redis(redisOptions);

    this.client.connect().then(() => {
      this.isConnected = true;
      this.logger.log(`Successfully connected to Redis at ${host}:${port}`);
    }).catch(err => {
      this.logger.warn(`Redis connection failed: ${err.message}. Operating in fallback mode.`);
    });
  }

  async onModuleDestroy() {
    if (this.client) {
      await this.client.quit().catch(() => {});
    }
    if (this.subscriber) {
      await this.subscriber.quit().catch(() => {});
    }
  }

  getClient(): Redis {
    return this.client;
  }

  // Presence Tracking
  async setUserOnline(userId: string, socketId: string): Promise<void> {
    if (!this.isConnected) return;
    try {
      const pipeline = this.client.pipeline();
      pipeline.sadd(`presence:sockets:${userId}`, socketId);
      pipeline.hset('presence:users', userId, 'online');
      pipeline.hdel('presence:last_seen', userId);
      await pipeline.exec();
    } catch (e) {
      this.logger.error(`Error setting user online in Redis: ${e.message}`);
    }
  }

  async setUserOffline(userId: string, socketId: string): Promise<{ isCompletelyOffline: boolean; lastSeen: Date }> {
    const now = new Date();
    if (!this.isConnected) return { isCompletelyOffline: true, lastSeen: now };
    try {
      await this.client.srem(`presence:sockets:${userId}`, socketId);
      const remainingSockets = await this.client.scard(`presence:sockets:${userId}`);
      if (remainingSockets === 0) {
        const pipeline = this.client.pipeline();
        pipeline.hset('presence:users', userId, 'offline');
        pipeline.hset('presence:last_seen', userId, now.toISOString());
        await pipeline.exec();
        return { isCompletelyOffline: true, lastSeen: now };
      }
      return { isCompletelyOffline: false, lastSeen: now };
    } catch (e) {
      this.logger.error(`Error setting user offline in Redis: ${e.message}`);
      return { isCompletelyOffline: true, lastSeen: now };
    }
  }

  async getUserPresence(userId: string): Promise<{ isOnline: boolean; lastSeen?: Date }> {
    if (!this.isConnected) return { isOnline: false };
    try {
      const status = await this.client.hget('presence:users', userId);
      if (status === 'online') {
        return { isOnline: true };
      }
      const lastSeenStr = await this.client.hget('presence:last_seen', userId);
      return {
        isOnline: false,
        lastSeen: lastSeenStr ? new Date(lastSeenStr) : undefined,
      };
    } catch (e) {
      return { isOnline: false };
    }
  }

  // Ephemeral Typing Status (Auto-expires in 4 seconds)
  async setTyping(conversationId: string, userId: string): Promise<void> {
    if (!this.isConnected) return;
    try {
      await this.client.set(`typing:${conversationId}:${userId}`, '1', 'EX', 4);
    } catch (e) {
      this.logger.error(`Error setting typing status in Redis: ${e.message}`);
    }
  }

  async clearTyping(conversationId: string, userId: string): Promise<void> {
    if (!this.isConnected) return;
    try {
      await this.client.del(`typing:${conversationId}:${userId}`);
    } catch (e) {
      this.logger.error(`Error clearing typing status in Redis: ${e.message}`);
    }
  }
}
