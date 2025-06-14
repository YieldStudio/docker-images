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

- `rg.fr-par.scw.cloud/yieldstudio/php:<version>-nginx`
- `rg.fr-par.scw.cloud/yieldstudio/php:<version>-unit`

**Examples:**

- `rg.fr-par.scw.cloud/yieldstudio/php:8.2-nginx`
- `rg.fr-par.scw.cloud/yieldstudio/php:8.3-unit`
- `rg.fr-par.scw.cloud/yieldstudio/php:8.4-nginx`

## Laravel Automation

These images include automation scripts in [`php/entrypoint.d/`](php/entrypoint.d/) to simplify running Laravel applications in containers:

- [`55-filament-automation.sh`](php/entrypoint.d/55-filament-automation.sh): Automates common Laravel tasks such as running migrations, clearing cache, and managing queues at container startup.
- [`60-handle-db-endpoint.sh`](php/entrypoint.d/60-handle-db-endpoint.sh): Handles dynamic database endpoint configuration, useful for cloud environments.

You can customize or extend these scripts to fit your deployment needs.

## Usage

### Using with Docker CLI

```bash
docker run --rm -it rg.fr-par.scw.cloud/yieldstudio/php:8.3-nginx php -v
```

### Using in a Docker Compose file

```yaml
services:
  app:
    image: rg.fr-par.scw.cloud/yieldstudio/php:8.3-unit
    ports:
      - "8080:8080"
    volumes:
      - ./src:/var/www/html
```

### Using [Laravel Sail](https://laravel.com/docs/12.x/sail)

TODO

## Extending the Image & Adding PHP Extensions

To add more PHP extensions or customize the image, create your own `Dockerfile` based on these images.

### Example: Adding PHP Extensions

```dockerfile
FROM rg.fr-par.scw.cloud/yieldstudio/php:8.3-nginx

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
FROM rg.fr-par.scw.cloud/yieldstudio/php:8.3-nginx

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