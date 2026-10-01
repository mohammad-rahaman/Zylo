import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { BadRequestException } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { Message, MessageType } from '../database/schemas/message.schema';
import { Conversation } from '../database/schemas/conversation.schema';
import { UsersService } from '../users/users.service';
import { MomentsService } from '../moments/moments.service';

describe('MessagesService', () => {
  let service: MessagesService;
  let messageModel: any;
  let conversationModel: any;
  let usersService: any;
  let momentsService: any;

  beforeEach(async () => {
    messageModel = {
      create: jest.fn(),
      find: jest.fn(),
      findById: jest.fn(),
      save: jest.fn(),
    };

    conversationModel = {
      findById: jest.fn(),
      findByIdAndUpdate: jest.fn(),
    };

    usersService = {
      isUserBlocked: jest.fn().mockResolvedValue(false),
    };

    momentsService = {
      recordInteraction: jest.fn().mockResolvedValue(null),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MessagesService,
        { provide: getModelToken(Message.name), useValue: messageModel },
        { provide: getModelToken(Conversation.name), useValue: conversationModel },
        { provide: UsersService, useValue: usersService },
        { provide: MomentsService, useValue: momentsService },
      ],
    }).compile();

    service = module.get<MessagesService>(MessagesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should throw BadRequestException if conversationId is invalid', async () => {
    await expect(
      service.sendMessage('invalid_id', '507f1f77bcf86cd799439011', {
        type: MessageType.TEXT,
        content: 'Hi',
      }),
    ).rejects.toThrow(BadRequestException);
  });
});
