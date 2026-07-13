FROM ghcr.io/cirruslabs/flutter:stable AS builder
WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginx:1.27-alpine
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 10000
CMD ["/bin/sh", "-c", "envsubst '${PORT:-10000}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'" ]
