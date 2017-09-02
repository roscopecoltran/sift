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

export LIBICONV_VER=${LIBICONV_VCS_BRANCH}
export LIBICONV_VERSION=${LIBICONV_VCS_BRANCH}
export LIBICONV_VERSION=${LIBICONV_VERSION:-"1.15"}

# Install build deps
apk --no-cache --no-progress --virtual .libiconv-build-deps add g++ gcc musl-dev musl make autoconf automake
wget -nc http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz -O /tmp/libiconv-${LIBICONV_VERSION}.tar.gz

if [ -d /usr/src/libiconv-${LIBICONV_VERSION} ]; then
	rm -fR /usr/src/libiconv-${LIBICONV_VERSION}
fi

cd /usr/src/libiconv-${LIBICONV_VERSION}
./configure --prefix=/usr/local
make -j${CONTAINER_NB_CORES} && make install && libtool --finish /usr/local/lib

# Remove build deps
# apk --no-cache --no-progress del .libiconv-build-deps

# Cleanup
rm -r ${LIBICONV_VCS_PATH}