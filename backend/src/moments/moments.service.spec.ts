import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { BadRequestException } from '@nestjs/common';
import { Types } from 'mongoose';
import { MomentsService } from './moments.service';
import {
  Moment,
  MomentStatus,
  normalizeParticipants,
} from '../database/schemas/moment.schema';
import { User } from '../database/schemas/user.schema';
import { MomentShortcut } from '../database/schemas/moment-shortcut.schema';
import { ConversationsService } from '../conversations/conversations.service';
import { MessagesService } from '../messages/messages.service';
import { UsersService } from '../users/users.service';

describe('MomentsService Unit Tests', () => {
  let service: MomentsService;
  let momentModel: any;
  let userModel: any;
  let shortcutModel: any;
  let conversationsService: any;
  let messagesService: any;
  let usersService: any;

  const userRahulId = '660000000000000000000001';
  const userAnanyaId = '660000000000000000000002';
  const userKarthikId = '660000000000000000000003';

  beforeEach(async () => {
    momentModel = {
      findOne: jest.fn(),
      find: jest.fn(),
      findById: jest.fn(),
      create: jest.fn(),
      findOneAndUpdate: jest.fn(),
      findByIdAndUpdate: jest.fn(),
    };

    userModel = {
      findById: jest.fn(),
      exists: jest.fn(),
    };

    shortcutModel = {
      find: jest.fn().mockReturnValue({
        populate: jest.fn().mockReturnValue({
          sort: jest.fn().mockReturnValue({
            exec: jest.fn().mockResolvedValue([]),
          }),
        }),
      }),
      findById: jest.fn().mockReturnValue({
        populate: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(null),
        }),
      }),
      findOne: jest.fn(),
      create: jest.fn(),
      deleteOne: jest.fn(),
    };

    conversationsService = {
      getOrCreateOneToOne: jest.fn(),
    };

    messagesService = {
      sendMessage: jest.fn(),
    };

    usersService = {
      isUserBlocked: jest.fn().mockResolvedValue(false),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MomentsService,
        { provide: getModelToken(Moment.name), useValue: momentModel },
        { provide: getModelToken(User.name), useValue: userModel },
        { provide: getModelToken(MomentShortcut.name), useValue: shortcutModel },
        { provide: ConversationsService, useValue: conversationsService },
        { provide: MessagesService, useValue: messagesService },
        { provide: UsersService, useValue: usersService },
      ],
    }).compile();

    service = module.get<MomentsService>(MomentsService);
  });

  describe('Participant Normalization', () => {
    it('Rahul + Ananya and Ananya + Rahul resolve to the exact same Moment pair', () => {
      const pair1 = normalizeParticipants(userRahulId, userAnanyaId);
      const pair2 = normalizeParticipants(userAnanyaId, userRahulId);

      expect(pair1.participantA.toString()).toEqual(pair2.participantA.toString());
      expect(pair1.participantB.toString()).toEqual(pair2.participantB.toString());
    });
  });

  describe('startMoment', () => {
    it('should throw BadRequestException if trying to start a Moment with oneself', async () => {
      await expect(service.startMoment(userRahulId, userRahulId)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('returns existing active Moment idempotently without creating a duplicate', async () => {
      userModel.findById.mockResolvedValue({ _id: new Types.ObjectId(userAnanyaId) });

      const existingMoment = {
        _id: new Types.ObjectId('660000000000000000000099'),
        participantA: new Types.ObjectId(userRahulId),
        participantB: new Types.ObjectId(userAnanyaId),
        currentCount: 5,
        status: MomentStatus.ACTIVE,
        expiresAt: new Date(Date.now() + 1000 * 60 * 60 * 12),
        currentWindowStartedAt: new Date(),
        startedAt: new Date(),
        participants: [
          { _id: new Types.ObjectId(userRahulId), displayName: 'Rahul' },
          { _id: new Types.ObjectId(userAnanyaId), displayName: 'Ananya' },
        ],
      };

      momentModel.findOne.mockResolvedValue(existingMoment);

      const result = await service.startMoment(userRahulId, userAnanyaId);

      expect(momentModel.create).not.toHaveBeenCalled();
      expect(result.currentCount).toBe(5);
      expect(result.status).toBe(MomentStatus.ACTIVE);
    });
  });

  describe('Rolling 24-Hour Mutual Interaction Rules', () => {
    it('First interaction records timestamp without incrementing count or extending timer', async () => {
      const now = new Date();
      const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000);

      const moment = {
        _id: new Types.ObjectId('660000000000000000000099'),
        participantA: new Types.ObjectId(userRahulId),
        participantB: new Types.ObjectId(userAnanyaId),
        currentCount: 0,
        status: MomentStatus.ACTIVE,
        currentWindowStartedAt: now,
        expiresAt,
        participantAInteractedAt: null,
        participantBInteractedAt: null,
      };

      momentModel.findOne.mockResolvedValue(moment);
      momentModel.findByIdAndUpdate.mockResolvedValue(moment);

      await service.recordInteraction(userRahulId, userAnanyaId);

      expect(momentModel.findByIdAndUpdate).toHaveBeenCalled();
      expect(momentModel.findOneAndUpdate).not.toHaveBeenCalled();
    });

    it('Second participant interaction within active window completes window and increments count by 1', async () => {
      const windowStart = new Date(Date.now() - 1000 * 60 * 60 * 2); // 2 hours ago
      const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 22);

      const moment = {
        _id: new Types.ObjectId('660000000000000000000099'),
        participantA: new Types.ObjectId(userRahulId),
        participantB: new Types.ObjectId(userAnanyaId),
        currentCount: 3,
        status: MomentStatus.ACTIVE,
        currentWindowStartedAt: windowStart,
        expiresAt,
        participantAInteractedAt: windowStart,
        participantBInteractedAt: null,
      };

      const updatedMoment = {
        ...moment,
        currentCount: 4,
        participantBInteractedAt: new Date(),
        currentWindowStartedAt: new Date(),
        lastCompletedAt: new Date(),
      };

      momentModel.findOne.mockResolvedValue(moment);
      momentModel.findOneAndUpdate.mockResolvedValue(updatedMoment);

      const result = await service.recordInteraction(userAnanyaId, userRahulId);

      expect(momentModel.findOneAndUpdate).toHaveBeenCalledWith(
        expect.objectContaining({ _id: moment._id }),
        expect.objectContaining({
          $inc: { currentCount: 1 },
          $set: expect.objectContaining({
            status: MomentStatus.ACTIVE,
          }),
        }),
        { new: true },
      );
      expect(result?.currentCount).toBe(4);
    });

    it('Multiple interactions from both participants do NOT repeatedly increment or extend timer', async () => {
      const now = new Date();
      const moment = {
        _id: new Types.ObjectId('660000000000000000000099'),
        participantA: new Types.ObjectId(userRahulId),
        participantB: new Types.ObjectId(userAnanyaId),
        currentCount: 4,
        status: MomentStatus.ACTIVE,
        currentWindowStartedAt: now,
        lastCompletedAt: now,
        expiresAt: new Date(now.getTime() + 24 * 60 * 60 * 1000),
        participantAInteractedAt: now,
        participantBInteractedAt: now,
      };

      momentModel.findOne.mockResolvedValue(moment);

      await service.recordInteraction(userRahulId, userAnanyaId);
      await service.recordInteraction(userRahulId, userAnanyaId);

      expect(momentModel.findOneAndUpdate).not.toHaveBeenCalled();
      expect(moment.currentCount).toBe(4);
    });

    it('Expired Moment cannot be interacted with and transitions to EXPIRED', async () => {
      const moment = {
        _id: new Types.ObjectId(),
        participantA: new Types.ObjectId(userRahulId),
        participantB: new Types.ObjectId(userAnanyaId),
        currentCount: 10,
        status: MomentStatus.ACTIVE,
        expiresAt: new Date(Date.now() - 1000),
        save: jest.fn().mockResolvedValue(true),
      };

      momentModel.findOne.mockResolvedValue(moment);

      const result = await service.recordInteraction(userRahulId, userAnanyaId);

      expect(moment.status).toBe(MomentStatus.EXPIRED);
      expect(result).toBeNull();
    });
  });

  describe('Multi-Recipient Send & Shortcuts', () => {
    it('sendMoment dispatches media to multiple recipients independently', async () => {
      const conv = { _id: new Types.ObjectId() };
      conversationsService.getOrCreateOneToOne.mockResolvedValue(conv);
      messagesService.sendMessage.mockResolvedValue({ _id: new Types.ObjectId() });
      userModel.findById.mockResolvedValue({ _id: new Types.ObjectId() });

      jest.spyOn(service, 'startMoment').mockResolvedValue({} as any);
      jest.spyOn(service, 'getMomentWithUser').mockResolvedValue({ currentCount: 1 } as any);

      const response = await service.sendMoment(userRahulId, {
        mediaUrl: 'https://cdn.zylo.app/photo_123.jpg',
        recipientIds: [userAnanyaId, userKarthikId],
        caption: 'Look at this!',
        filter: 'orange_pop',
      });

      expect(response.success).toBe(true);
      expect(response.results.length).toBe(2);
      expect(conversationsService.getOrCreateOneToOne).toHaveBeenCalledTimes(2);
      expect(messagesService.sendMessage).toHaveBeenCalledTimes(2);
    });

    it('createShortcut validates contacts and creates shortcut', async () => {
      userModel.exists.mockResolvedValue(true);
      const createdShortcut = {
        _id: new Types.ObjectId(),
        ownerId: new Types.ObjectId(userRahulId),
        name: 'Besties',
        emoji: '✨',
        contactIds: [
          {
            _id: new Types.ObjectId(userAnanyaId),
            username: 'ananya',
            displayName: 'Ananya',
            profilePhoto: '',
            isOnline: true,
            lastSeen: new Date(),
          },
        ],
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      shortcutModel.create.mockResolvedValue({ _id: createdShortcut._id });
      shortcutModel.findById.mockReturnValue({
        populate: jest.fn().mockReturnValue({
          exec: jest.fn().mockResolvedValue(createdShortcut),
        }),
      });

      const shortcut = await service.createShortcut(userRahulId, {
        name: 'Besties',
        emoji: '✨',
        contactIds: [userAnanyaId],
      });

      expect(shortcut.name).toBe('Besties');
      expect(shortcut.contacts.length).toBe(1);
      expect(shortcut.contacts[0].username).toBe('ananya');
    });
  });
});
