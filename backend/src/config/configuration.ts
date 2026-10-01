export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  apiPrefix: process.env.API_PREFIX || 'api/v1',
  corsOrigin: process.env.CORS_ORIGIN || '*',
  database: {
    uri: process.env.MONGODB_URI || 'mongodb://localhost:27017/zylo',
  },
  redis: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
    password: process.env.REDIS_PASSWORD || undefined,
  },
  jwt: {
    accessSecret: process.env.JWT_ACCESS_SECRET || 'zylo_access_secret_123',
    accessExpiration: process.env.JWT_ACCESS_EXPIRATION || '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET || 'zylo_refresh_secret_456',
    refreshExpiration: process.env.JWT_REFRESH_EXPIRATION || '7d',
  },
  uploads: {
    driver: process.env.UPLOAD_DRIVER || 'local',
    destination: process.env.UPLOAD_DESTINATION || './uploads',
    maxSizeBytes: parseInt(process.env.MAX_FILE_SIZE_BYTES, 10) || 25 * 1024 * 1024,
    cloudinary: {
      cloudName: process.env.CLOUDINARY_CLOUD_NAME || '',
      apiKey: process.env.CLOUDINARY_API_KEY || '',
      apiSecret: process.env.CLOUDINARY_API_SECRET || '',
    },
  },
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || '',
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
    privateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  },
});
