#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
    source ${COMMON_SCRIPT}
fi

# Set temp environment vars
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
export PHP5_VERSION=${PHP5_VERSION:-"5.7"}

export PHP5_BUILD_CONF=" \
    --prefix=/usr \
    --libdir=/usr/lib/php \
    --datadir=/usr/share/php \
    --sysconfdir=/php/etc \
    --localstatedir=/php/var \
    --with-pear=/usr/share/php \
    --with-config-file-scan-dir=/php/conf.d \
    --with-config-file-path=/php \
    --with-pic \
    --disable-short-tags \
    --without-readline \
    --enable-bcmath=shared \
    --enable-fpm \
    --disable-cgi \
    --enable-mysqlnd \
    --enable-mbstring \
    --with-curl \
    --with-libedit \
    --with-openssl \
    --with-iconv=/usr/local \
    --with-gd \
    --with-jpeg-dir \
    --with-png-dir \
    --with-webp-dir \
    --with-xpm-dir=no \
    --with-freetype-dir \
    --enable-gd-native-ttf \
    --disable-gd-jis-conv \
    --with-zlib"

export PHP5_BUILD_EXT_LIST=" \
    mysqli \
    ctype \
    dom \
    json \
    xml \
    mbstring \
    posix \
    xmlwriter \
    zip \
    zlib \
    sqlite3 \
    pdo_sqlite \
    pdo_pgsql \
    pdo_mysql \
    pcntl \
    curl \
    fileinfo \
    bz2 \
    intl \
    mcrypt \
    openssl \
    ldap \
    simplexml \
    pgsql \
    ftp \
    exif \
    gmp"

export PHP5_CUSTOM_BUILD_PKGS=" \
    freetype-dev \
    openldap-dev \
    gmp-dev \
    libmcrypt-dev \
    icu-dev \
    postgresql-dev \
    libpng-dev \
    libwebp-dev \
    gd-dev \
    libjpeg-turbo-dev \
    libxpm-dev \
    libedit-dev \
    libxml2-dev \
    libressl-dev \
    libbz2 \
    sqlite-dev"

export PHP5_CUSTOM_PKGS=" \
    freetype \
    openldap \
    gmp \
    libmcrypt \
    bzip2-dev \
    icu \
    libpq"

export APK_BUILD_DEPS=" \
    linux-headers \
    libtool \
    build-base \
    pcre-dev \
    zlib-dev \
    wget \
    gnupg \
    autoconf \
    gcc \
    g++ \
    libc-dev \
    make \
    pkgconf \
    curl-dev \
    ca-certificates \
    ${PHP5_CUSTOM_BUILD_PKGS}"

# Install build deps
apk --no-cache --no-progress --virtual .php5-build-deps add ${APK_BUILD_DEPS} \
    s6 \
    su-exec \
    curl \
    libedit \
    libxml2 \
    libressl \
    libwebp \
    gd \
    pcre \
    zlib \
    ${PHP5_CUSTOM_PKGS}

export PHP5_DEPS_SRC="iconv"
for dep in ${PHP5_DEPS_SRC}; do
    DEP_EXECUTABLE=$(which $dep) 
    if [ ! -f ${DEP_EXECUTABLE} ]; then
        cd /app 
        pwd
        chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
        ./shared/scripts/docker/shell/install-${dep}.sh
    fi
done    

wget -nc ${PHP5_MIRROR}/get/php-${PHP5_VERSION}.tar.gz/from/this/mirror -O /tmp/php-${PHP5_VERSION}.tar.gz
wget -nc ${PHP5_MIRROR}/get/php-${PHP5_VERSION}.tar.gz.asc/from/this/mirror -O /tmp/php-${PHP5_VERSION}.tar.gz.asc

if [ -d /tmp/php-${PHP5_VERSION} ];then
    rm -fR /tmp/php-${PHP5_VERSION}/
fi

tar xzvf /tmp/php-${PHP5_VERSION}.tar.gz -C /usr/src
mv /usr/src/php-${PHP5_VERSION} /usr/src/php

cd /usr/src/php
./configure CFLAGS="-O3 -fstack-protector-strong" ${PHP5_BUILD_CONF}
make -j ${CONTAINER_NB_CORES}
make install

# Remove build deps
# apk --no-cache --no-progress del .php5-build-deps

# Cleanup
rm -r ${PHP5_VCS_PATH}