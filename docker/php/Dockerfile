FROM php:fpm-alpine

MAINTAINER Yohann Marillet <yohann.marillet@gmail.com>

RUN apk --update --no-cache add \
    git \
    libzip \
        libzip-dev \
    unzip \
	icu-dev \
	g++ \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libgd \
	libcurl \
	curl-dev \
	bash \
	bash-completion \
    yaml \
    nano \
    tar \
    make \
    libffi-dev \
    ruby ruby-irb ruby-rake ruby-io-console ruby-bigdecimal ruby-json ruby-bundler ruby-dev ruby-rdoc \
    libstdc++ tzdata ca-certificates \
    && gem install sass --no-user-install

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version

# Set timezone
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN "date"

# Type docker-php-ext-install to see available extensions
RUN docker-php-ext-configure gd \
            --with-freetype=/usr/include/ \
            --with-jpeg=/usr/include/ \
    && docker-php-ext-install -j$(nproc) zip intl gd sockets bcmath

WORKDIR /opt/sources
