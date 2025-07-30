ARG BASE_OS_VERSION='bookworm'
ARG PHP_VERSION='8.4'
ARG PHP_VARIATION='cli'
ARG BASE_IMAGE="php:${PHP_VERSION}-${PHP_VARIATION}-${BASE_OS_VERSION}"

##########
# CLI: Main Image
##########
FROM ${BASE_IMAGE}

ARG DEPENDENCY_PACKAGES_ALPINE='shadow gettext icu-data-full'
ARG DEPENDENCY_PACKAGES_DEBIAN='procps gettext-base zip'
ARG DEPENDENCY_PHP_EXTENSIONS='opcache pcntl pdo_mysql pdo_pgsql redis zip intl gd bcmath exif imagick'

ENV APP_BASE_DIR=/var/www/html \
    COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME=/composer \
    COMPOSER_MAX_PARALLEL_HTTP=24 \
    DISABLE_DEFAULT_CONFIG=false \
    LOG_OUTPUT_LEVEL=warn \
    PHP_DATE_TIMEZONE="UTC" \
    PHP_DISPLAY_ERRORS=Off \
    PHP_DISPLAY_STARTUP_ERRORS=Off \
    PHP_ERROR_LOG="/dev/stderr" \
    PHP_ERROR_REPORTING="22527" \
    PHP_MAX_EXECUTION_TIME="99" \
    PHP_MAX_INPUT_TIME="-1" \
    PHP_MAX_INPUT_VARS="1000" \
    PHP_MEMORY_LIMIT="256M" \
    PHP_OPCACHE_ENABLE="0" \
    PHP_OPCACHE_FORCE_RESTART_TIMEOUT="180" \
    PHP_OPCACHE_INTERNED_STRINGS_BUFFER="8" \
    PHP_OPCACHE_JIT="off" \
    PHP_OPCACHE_JIT_BUFFER_SIZE="0" \
    PHP_OPCACHE_MAX_ACCELERATED_FILES="10000" \
    PHP_OPCACHE_MEMORY_CONSUMPTION="128" \
    PHP_OPCACHE_REVALIDATE_FREQ="2" \
    PHP_OPCACHE_SAVE_COMMENTS="1" \
    PHP_OPCACHE_VALIDATE_TIMESTAMPS="1" \
    PHP_OPEN_BASEDIR="" \
    PHP_POST_MAX_SIZE="100M" \
    PHP_SESSION_COOKIE_SECURE=false \
    PHP_UPLOAD_MAX_FILE_SIZE="100M" \
    SHOW_WELCOME_MESSAGE=true

# copy our scripts
COPY --chmod=755 common/ /

# install pecl extensions & dependencies
RUN docker-php-dep-install-alpine "${DEPENDENCY_PACKAGES_ALPINE}" && \
    docker-php-dep-install-debian "${DEPENDENCY_PACKAGES_DEBIAN}"  && \
    docker-php-install-php-ext-installer && \
    \
    # Ensure /var/www/ has the correct permissions
    chown -R www-data:www-data /var/www && \
    chmod -R 755 /var/www && \
    \
    # Make composer cache directory
    mkdir -p "${COMPOSER_HOME}" && \
    chown -R www-data:www-data "${COMPOSER_HOME}" && \
    \
    # Install default PHP extensions
    install-php-extensions "${DEPENDENCY_PHP_EXTENSIONS}"

# install composer from Composer's official Docker image
COPY --from=composer/composer:2 /usr/bin/composer /usr/bin/composer

RUN docker-php-set-file-permissions --owner www-data:www-data --service cli

WORKDIR ${APP_BASE_DIR}

USER www-data

ENTRYPOINT ["docker-php-entrypoint"]
