# Uses composer official image
#  only to import it to "main" php
#  service

FROM php:8.0.3-fpm AS compiled-amqp

RUN apt-get update \
	&& apt-get install -y -f librabbitmq-dev \
		libssh-dev \
	&& docker-php-source extract \
	&& mkdir /usr/src/php/ext/amqp \
	&& curl -L https://github.com/php-amqp/php-amqp/archive/master.tar.gz | tar -xzC /usr/src/php/ext/amqp --strip-components=1 \
	&& docker-php-ext-install amqp \
	&& docker-php-ext-enable amqp

FROM composer:2.0.12 AS composer

FROM php:8.0.3-fpm

COPY --from=composer /usr/bin/composer /usr/bin/

ENV COMPOSER_ALLOW_SUPERUSER 1

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    libonig-dev \
    libicu-dev \ 
    libzip-dev \
    libpq-dev \
    libpng-dev \
    librabbitmq-dev \
    && apt-get autoremove -y && apt-get autoclean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

    
RUN docker-php-ext-install \
    opcache \
    intl \
    zip \
    pdo_pgsql \
    gd

RUN pecl install redis && docker-php-ext-enable redis

COPY --from=compiled-amqp /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp.so /usr/local/lib/php/extensions/no-debug-non-zts-20200930/amqp.so
COPY --from=compiled-amqp /usr/local/etc/php/conf.d/docker-php-ext-amqp.ini /usr/local/etc/php/conf.d/docker-php-ext-amqp.ini

RUN pecl install xdebug-3.0.4 && \
    docker-php-ext-enable xdebug && \
    echo "xdebug.mode=off" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    echo "xdebug.log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

RUN printf '[PHP]\ndate.timezone = "Europe/Lisbon"\n' > /usr/local/etc/php/conf.d/tzone.ini

RUN curl https://get.symfony.com/cli/installer --output /tmp/symfony && \
    chmod a+x /tmp/symfony && \
    cd /tmp && ./symfony --install-dir=/usr/bin && \
    rm ./symfony
