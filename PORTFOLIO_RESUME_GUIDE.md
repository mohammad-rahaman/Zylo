# Zylo — Senior Portfolio & Resume Presentation Guide 🚀

> A comprehensive reference guide for presenting **Zylo** as a centerpiece project on your resume, LinkedIn, GitHub, and during technical engineering interviews.

---

## 📌 Executive Summary (The 30-Second Elevator Pitch)

> **"Zylo is a high-performance, production-grade cross-platform messaging platform built with Flutter (Material 3 & Riverpod) and NestJS (TypeScript, MongoDB Atlas, Redis, and Socket.IO). It features bi-directional low-latency messaging, Redis-backed live presence and ephemeral typing tracking, automated dual-token JWT authentication with silent re-issuance, cursor-based message pagination, multi-driver media processing (Cloudinary & local disk), and an automated GitHub Actions CI pipeline."**

---

## 📄 Tailored Resume Bullet Points

Copy and adapt these bullet points for your resume based on the role you are targeting:

### For Mobile / Flutter Engineer Roles
- **Architected and developed Zylo**, a production-ready, cross-platform messaging application for iOS, Android, macOS, and Web using **Flutter 3.x, Dart 3.x, and Riverpod 2.x**.
- **Designed a custom Material 3 design system** featuring a tailored dark palette, Instrument Serif typography, responsive layouts, and zero-jank micro-animations.
- **Engineered real-time bi-directional communication** over WebSocket using Socket.IO with optimistic message updates, auto-reconnection, and double-check delivery/read receipts.
- **Implemented resilient network layer** using Dio with automated refresh token rotation interceptors, preventing session drops during active chat sessions.
- **Wrote automated unit, repository, and widget tests** achieving comprehensive test coverage and enforced zero-warning static analysis via strict Flutter lint rules.

### For Full-Stack / Backend Engineer Roles
- **Built an enterprise-grade modular backend** in **NestJS (TypeScript)** utilizing Mongoose (MongoDB 7.x) and ioredis (Redis 7.x) adhering to clean domain-driven architecture.
- **Designed high-throughput real-time WebSocket gateways** handling authenticated handshake verification, isolated user/conversation rooms, and low-latency message routing.
- **Engineered Redis-backed presence tracking** with auto-expiring ephemeral typing status (4s TTL) and sub-millisecond online/offline status lookups.
- **Implemented database schema optimizations** including monotonic cursor-based pagination on `_id`, compound indexes for 1-on-1 conversations, and TTL indexes for session expiry.
- **Established Docker & Docker Compose stack** with multi-stage production builds, non-root container security, Nginx SPA proxying, and automated GitHub Actions CI.

---

## 🧠 Technical Interview Deep Dives & Answers

### 1. "How does the real-time presence and typing system work without melting the database?"
> **Answer:**
> *"Instead of polling MongoDB for user status, Zylo offloads all ephemeral state to Redis. When a user connects to the Socket.IO gateway, their socket ID is registered in a Redis Set (`presence:sockets:{userId}`) and marked `'online'` in a Redis Hash. When all client sockets disconnect, the user is transitioned to `'offline'` and an ISO `lastSeen` timestamp is saved. Typing indicators are stored with a 4-second TTL (`SET typing:{conversationId}:{userId} 1 EX 4`), ensuring that if a user disconnects or stops typing abruptly, the indicator expires automatically without requiring explicit teardown."*

### 2. "Why use cursor-based pagination instead of page/limit offset pagination?"
> **Answer:**
> *"In chat applications, messages arrive continuously while the user is reading history. Traditional offset pagination (`skip(page * limit)`) suffers from two major flaws:
> 1. **Data drift / duplicate items:** If new messages arrive while scrolling up, offset shifting causes the user to see duplicate messages or miss messages.
> 2. **Performance degradation:** High offset values force MongoDB to scan and discard documents sequentially ($O(N)$).
> 
> Zylo solves this by using MongoDB's strictly monotonic `_id` as a cursor (`filter._id = { $lt: ObjectId(cursor) }`). Combined with a compound index `{ conversationId: 1, _id: -1 }`, queries run in $O(\log N)$ time with index-only seek and zero pagination drift."*

### 3. "How does silent token refresh work on the client?"
> **Answer:**
> *"Zylo uses a dual-token JWT architecture: short-lived access tokens (15m) and rotating refresh tokens (7d). On the Flutter client, a custom Dio `InterceptorsWrapper` catches `401 Unauthorized` responses. If a request fails with 401, the interceptor pauses the request pipeline, retrieves the secure refresh token from `FlutterSecureStorage`, calls the `/api/auth/refresh` endpoint using a separate un-intercepted Dio instance, securely stores the new token pair, updates the `Authorization` header, and transparently retries the original failed request without logging out the user or interrupting the UI."*

### 4. "How is optimistic UI handled in the chat screen?"
> **Answer:**
> *"When a user taps send, a local message object with a UUID `tempId` and status `MessageStatus.sending` is immediately inserted at index 0 of the Riverpod state list. The message is transmitted concurrently over the WebSocket connection with `tempId`. When the server acknowledges message creation or broadcasts `message:new`, the client reconciles the existing list by replacing the item matching `tempId` with the server-verified message, seamlessly transitioning the checkmark status from pending to sent."*

---

## 🛠️ Tech Stack & Key Architectural Highlights

| Layer | Technologies | Key Highlights |
| :--- | :--- | :--- |
| **Mobile & Web UI** | Flutter 3.x, Dart 3.x | Material 3, Warm Ember color system, Instrument Serif display typography |
| **State Management** | Flutter Riverpod 2.x | Unidirectional data flow, auto-disposing family providers, immutable state |
| **Client Networking** | Dio, Socket.IO Client | Automated refresh token interceptor, WebSocket fallback, FlutterSecureStorage |
| **Backend Framework**| NestJS 10.x, Express | Domain modules, dependency injection, Swagger OpenAPI, class-validator DTOs |
| **Data Persistence** | MongoDB 7.x, Mongoose 8.x | Compound indexes, cursor pagination, TTL collections, soft-deletes |
| **In-Memory Cache**  | Redis 7.2, ioredis | Ephemeral typing TTLs, multi-device socket presence sets, resilient fallbacks |
| **Media & Storage**  | Cloudinary CDN + Local Disk | MIME-type verification, 25MB stream uploaders, image/video/audio metadata |
| **Cloud Messaging**  | Firebase Admin SDK (FCM) | Multicast push notifications for offline users with automatic dead-token pruning |
| **DevOps & Containers** | Docker, Nginx, GitHub Actions | Multi-stage slim alpine images, non-root users, healthchecks, gzip compression |

---

## 📸 Portfolio Presentation Checklist

- [ ] **GitHub Banner & Badges:** Verified that root `README.md` includes interactive shields for Flutter, NestJS, TypeScript, MongoDB, Redis, and GitHub Actions CI.
- [ ] **Clean Git History:** Commits use conventional commit messages (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`).
- [ ] **Demo Video / GIF:** Record a 30-45 second screen recording demonstrating:
  - Account registration & immediate auto-login.
  - Sending a text message and seeing real-time sent/delivered/read double-check transitions.
  - Live typing indicator appearing on the second screen.
  - Photo attachment capture and upload.
  - Moments feature with rolling 24-hour streak indicator.
- [ ] **Live Swagger Docs:** Mention `http://localhost:3000/api/docs` or deploy the backend to Render/Railway for an active live demo link.

---

## 📝 GitHub Repository Topics

Make sure your repository has these topics enabled on GitHub:
`flutter`, `dart`, `nestjs`, `socket-io`, `mongodb`, `redis`, `realtime-chat`, `clean-architecture`, `riverpod`, `cross-platform`, `material-3`, `mobile-app`, `docker`, `typescript`
