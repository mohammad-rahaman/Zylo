import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import * as admin from 'firebase-admin';
import { DeviceToken, DeviceTokenDocument } from '../database/schemas/device-token.schema';

@Injectable()
export class NotificationsService implements OnModuleInit {
  private readonly logger = new Logger(NotificationsService.name);
  private firebaseInitialized = false;

  constructor(
    private configService: ConfigService,
    @InjectModel(DeviceToken.name) private deviceTokenModel: Model<DeviceTokenDocument>,
  ) {}

  onModuleInit() {
    const projectId = this.configService.get<string>('firebase.projectId');
    const clientEmail = this.configService.get<string>('firebase.clientEmail');
    const privateKey = this.configService.get<string>('firebase.privateKey');

    if (projectId && clientEmail && privateKey) {
      try {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey: privateKey.replace(/\\n/g, '\n'),
          }),
        });
        this.firebaseInitialized = true;
        this.logger.log('Firebase Admin SDK initialized successfully');
      } catch (e) {
        this.logger.warn(`Failed to initialize Firebase Admin SDK: ${e.message}`);
      }
    } else {
      this.logger.log('Firebase credentials not fully provided; notifications will operate in mock logging mode');
    }
  }

  async saveDeviceToken(userId: string, token: string, platform = 'unknown') {
    return this.deviceTokenModel.findOneAndUpdate(
      { userId: new Types.ObjectId(userId), token },
      {
        $set: {
          userId: new Types.ObjectId(userId),
          token,
          platform,
          updatedAt: new Date(),
        },
      },
      { upsert: true, new: true },
    );
  }

  async removeDeviceToken(token: string) {
    return this.deviceTokenModel.deleteOne({ token });
  }

  async sendPushToUser(
    userId: string,
    title: string,
    body: string,
    data: Record<string, string> = {},
  ) {
    const tokens = await this.deviceTokenModel
      .find({ userId: new Types.ObjectId(userId) })
      .lean();

    if (!tokens || tokens.length === 0) {
      return;
    }

    const registrationTokens = tokens.map((t) => t.token);

    if (this.firebaseInitialized) {
      try {
        const response = await admin.messaging().sendEachForMulticast({
          tokens: registrationTokens,
          notification: {
            title,
            body,
          },
          data,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              clickAction: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        });

        // Clean up invalid tokens
        if (response.failureCount > 0) {
          const tokensToRemove: string[] = [];
          response.responses.forEach((resp, idx) => {
            if (!resp.success) {
              const errCode = resp.error?.code;
              if (
                errCode === 'messaging/invalid-registration-token' ||
                errCode === 'messaging/registration-token-not-registered'
              ) {
                tokensToRemove.push(registrationTokens[idx]);
              }
            }
          });
          if (tokensToRemove.length > 0) {
            await this.deviceTokenModel.deleteMany({ token: { $in: tokensToRemove } });
          }
        }
      } catch (err) {
        this.logger.error(`Error sending push notification via Firebase: ${err.message}`);
      }
    } else {
      this.logger.log(
        `[MOCK FCM PUSH] To: ${userId} (${registrationTokens.length} tokens) | Title: "${title}" | Body: "${body}" | Data: ${JSON.stringify(data)}`,
      );
    }
  }
}
