# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy dependency specifications first to leverage Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and compile production web bundle
COPY . .
RUN flutter build web --release

# Stage 2: Production Nginx web server
FROM nginx:alpine

# Copy custom Nginx configuration for Flutter SPA routing
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled web assets from builder stage
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
