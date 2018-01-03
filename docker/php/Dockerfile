FROM php:fpm-alpine

MAINTAINER Yohann Marillet <yohann.marillet@gmail.com>

RUN apk --update --no-cache add \
    git \
    unzip \
	icu-dev \
	g++ \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
	libcurl \
	curl-dev \
	bash \
	bash-completion

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

# Set timezone
RUN rm /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN "date"

# Type docker-php-ext-install to see available extensions
RUN docker-php-ext-install zip intl json fileinfo gd iconv mbstring sockets hash curl bcmath ctype

WORKDIR /mnt/sources
