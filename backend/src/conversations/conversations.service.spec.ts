import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { BadRequestException } from '@nestjs/common';
import { ConversationsService } from './conversations.service';
import { Conversation } from '../database/schemas/conversation.schema';
import { Message } from '../database/schemas/message.schema';
import { User } from '../database/schemas/user.schema';
import { UsersService } from '../users/users.service';

describe('ConversationsService', () => {
  let service: ConversationsService;
  let conversationModel: any;
  let messageModel: any;
  let userModel: any;
  let usersService: any;

  beforeEach(async () => {
    conversationModel = {
      findOne: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
      find: jest.fn(),
      deleteOne: jest.fn(),
    };

    messageModel = {
      deleteMany: jest.fn(),
    };

    userModel = {
      findById: jest.fn(),
    };

    usersService = {
      isUserBlocked: jest.fn().mockResolvedValue(false),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConversationsService,
        { provide: getModelToken(Conversation.name), useValue: conversationModel },
        { provide: getModelToken(Message.name), useValue: messageModel },
        { provide: getModelToken(User.name), useValue: userModel },
        { provide: UsersService, useValue: usersService },
      ],
    }).compile();

    service = module.get<ConversationsService>(ConversationsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should not allow starting a conversation with oneself', async () => {
    await expect(
      service.getOrCreateOneToOne('507f1f77bcf86cd799439011', '507f1f77bcf86cd799439011'),
    ).rejects.toThrow(BadRequestException);
  });
});
