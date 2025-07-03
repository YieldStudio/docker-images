# Laravel Optimized PHP Docker Images

## Overview

This repository provides production-ready PHP Docker images based on [serversideup/docker-php](https://github.com/serversideup/docker-php).  
Two variants are available for each supported PHP version:

- **nginx**: PHP-FPM served by Nginx ([php/nginx.Dockerfile](php/nginx.Dockerfile))
- **unit**: [Nginx Unit](https://unit.nginx.org/) ([php/unit.Dockerfile](php/unit.Dockerfile))

## Supported PHP Versions

- 8.2
- 8.3
- 8.4

## Image Tags

Images are tagged as follows:

- `ghcr.io/yieldstudio/php:<version>-nginx`
- `ghcr.io/yieldstudio/php:<version>-unit`

**Examples:**

- `ghcr.io/yieldstudio/php:8.2-nginx`
- `ghcr.io/yieldstudio/php:8.3-unit`
- `ghcr.io/yieldstudio/php:8.4-nginx`

## Laravel Automation

These images include automation scripts in [`php/entrypoint.d/`](php/entrypoint.d/) to simplify running Laravel applications in containers:

- [`40-handle-db-endpoint.sh`](php/entrypoint.d/40-handle-db-endpoint.sh): Handles dynamic database endpoint configuration, useful for cloud environments.
- [`55-filament-automation.sh`](php/entrypoint.d/55-filament-automation.sh): Automates common Laravel tasks such as running migrations, clearing cache, and managing queues at container startup.

You can customize or extend these scripts to fit your deployment needs.

## Usage

### Using with Docker CLI

```bash
docker run --rm -it ghcr.io/yieldstudio/php:8.3-nginx php -v
```

### Using in a Docker Compose file

```yaml
services:
  app:
    image: ghcr.io/yieldstudio/php:8.3-unit
    ports:
      - "8080:8080"
    volumes:
      - ./src:/var/www/html
```

### Using [Laravel Sail](https://laravel.com/docs/12.x/sail)

1. Create your `Dockerfile`

<details>
  <summary>Expand to show the content</summary>

```Dockerfile
ARG PHP_VERSION=8.4
ARG NODE_VERSION=22

############################################
# Base Image
############################################
FROM ghcr.io/yieldstudio/php:${PHP_VERSION}-nginx AS base

ENV HEALTHCHECK_PATH="/up"

## Uncomment if you need to install additional PHP extensions
# USER root
# RUN install-php-extensions bcmath gd

############################################
# Development Image
############################################
FROM base AS development

ARG WWWUSER
ARG WWWGROUP
ARG NODE_VERSION=22
ARG MYSQL_CLIENT="mysql-client"
ARG POSTGRES_VERSION=17

ENV AUTORUN_ENABLED=false
ENV PHP_OPCACHE_ENABLE=0

ENV XDEBUG_MODE="off"
ENV XDEBUG_CONFIG="client_host=host.docker.internal"

USER root

RUN apt-get update && apt-get upgrade -y \
    && mkdir -p /etc/apt/keyrings \
    && apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python3 dnsutils librsvg2-bin fswatch ffmpeg nano  \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_VERSION.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && npm install -g pnpm \
    && npm install -g bun \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /etc/apt/keyrings/yarn.gpg >/dev/null \
    && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN docker-php-serversideup-set-id www-data $WWWUSER:$WWWGROUP \
    && docker-php-serversideup-set-file-permissions --owner $WWWUSER:$WWWGROUP --service nginx \
    && useradd -mNo -g www-data -u $(id -u www-data) sail

RUN install-php-extensions xdebug

USER www-data

############################################
# CI image
############################################
FROM base AS ci

ENV AUTORUN_ENABLED=false
ENV PHP_OPCACHE_ENABLE=0

ENV XDEBUG_MODE="coverage,debug"
ENV XDEBUG_CONFIG="client_host=host.docker.internal client_port=9003"

# Sometimes CI images need to run as root
# so we set the ROOT user and configure
# the PHP-FPM pool to run as www-data
USER root

RUN install-php-extensions xdebug

RUN echo "" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf && \
    echo "user = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf && \
    echo "group = www-data" >> /usr/local/etc/php-fpm.d/docker-php-serversideup-pool.conf

############################################
# 
############################################
FROM base AS composer

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY --chown=www-data:www-data composer.* ./
COPY --chown=www-data:www-data . .

RUN composer install --no-dev --no-interaction --no-scripts --prefer-dist \
    && composer dump-autoload --classmap-authoritative --no-dev --optimize

############################################
# Assets Build
############################################
FROM node:${NODE_VERSION}-slim AS frontend

WORKDIR /app

COPY package*.json *.config.js ./
COPY public/ ./public
COPY resources/ ./resources
COPY --from=composer /var/www/html/vendor ./vendor

RUN if [ -f yarn.lock ]; then \
        yarn install --frozen-lockfile && yarn run build; \
    elif [ -f package-lock.json ]; then \
        npm ci && npm run build; \
    elif [ -f pnpm-lock.yaml ]; then \
        pnpm install --frozen-lockfile && pnpm run build; \
    elif [ -f bun.lockb ]; then \
        bun install && bun run build; \
    else \
        echo "No lock file found, skipping asset build."; \
    fi

############################################
# Production Image
############################################
FROM base

ENV PHP_MEMORY_LIMIT=512M
ENV SSL_MODE=mixed

USER www-data

COPY --from=composer --chown=www-data:www-data /var/www/html/vendor ./vendor
COPY --from=frontend --chown=www-data:www-data /app/public/build ./public/build

COPY --chown=www-data:www-data . /var/www/html
```

</details>
<br/>

2. Edit your `docker-compose.yml`

```diff 
services:
    laravel.test:
        build:
-           context: './vendor/laravel/sail/runtimes/8.4'
+           context: '.'
+           dockerfile: Dockerfile
+           target: development
            args:
+               PHP_VERSION: 8.4
+               WWWUSER: '${WWWUSER}'
                WWWGROUP: '${WWWGROUP}'
+               NODE_VERSION: '22'
        image: 'sail-8.4/app'
        extra_hosts:
            - 'host.docker.internal:host-gateway'
        ports:
            - '${APP_PORT:-80}:8080'
            - '${VITE_PORT:-5173}:${VITE_PORT:-5173}'
        environment:
-           WWWUSER: '${WWWUSER}'
            LARAVEL_SAIL: 1
            XDEBUG_MODE: '${SAIL_XDEBUG_MODE:-off}'
            XDEBUG_CONFIG: '${SAIL_XDEBUG_CONFIG:-client_host=host.docker.internal}'
            IGNITION_LOCAL_SITES_PATH: '${PWD}'
        volumes:
            - '.:/var/www/html'
        networks:
            - sail
        depends_on:
            - mysql
            - redis
```

3. (Optional) Setup Queue and Scheduler

```diff 
services:
    ...

+   schedule:
+       image: 'sail-8.4/app'
+       command: ["php", "/var/www/html/artisan", "schedule:work"]
+       stop_signal: SIGTERM
+       healthcheck:
+           test: ["CMD", "healthcheck-schedule"]
+           start_period: 10s
+       volumes:
+           - '.:/var/www/html'
+       networks:
+           - sail
+       depends_on:
+           - laravel.test
+           - mysql
+           - redis

+   queue:
+       image: 'sail-8.4/app'
+       command: ["php", "/var/www/html/artisan", "queue:work", "--tries=3"]
+       stop_signal: SIGTERM
+       healthcheck:
+           test: ["CMD", "healthcheck-queue"]
+           start_period: 10s
+       volumes:
+           - '.:/var/www/html'
+       networks:
+           - sail
+       depends_on:
+           - laravel.test
+           - mysql
+           - redis
```

## Extending the Image & Adding PHP Extensions

To add more PHP extensions or customize the image, create your own `Dockerfile` based on these images.

### Example: Adding PHP Extensions

```dockerfile
FROM ghcr.io/yieldstudio/php:8.3-nginx

# Install additional PHP extensions
RUN install-php-extensions \
    redis \
    pcntl \
    intl
```

- The `install-php-extensions` tool (included via the base image) makes it easy to add most common extensions.
- You can also use `docker-php-ext-install` or `pecl install` for custom or less common extensions.

### Example: Using docker-php-ext-install

```dockerfile
FROM ghcr.io/yieldstudio/php:8.3-nginx

RUN docker-php-ext-install pdo_mysql
```

### Build Your Custom Image

```bash
docker build -t my-custom-php:8.3-nginx .
```

You can now use `my-custom-php:8.3-nginx` in your projects.

## Build & CI

Images are built and published automatically using [GitHub Actions](.github/workflows/build-php.yml) for all supported PHP versions and both variants (`nginx`, `unit`).  
Security scans are performed using Trivy.

---

For more information on configuration and customization, refer to the [serversideup/docker-php documentation](https://github.com/serversideup/docker-php).