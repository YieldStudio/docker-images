ARG PHP_VERSION=
ARG NODE_VERSION=22

FROM serversideup/php:${PHP_VERSION}-unit AS base

ENV SSL_MODE=off
ENV AUTORUN_ENABLED=true
ENV PHP_OPCACHE_ENABLE=1

COPY --chmod=755 ./entrypoint.d/ /etc/entrypoint.d/

USER root

WORKDIR /var/www/html/
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y git \    
    && install-php-extensions exif gd intl

USER www-data
