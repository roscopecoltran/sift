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

export SQLITE_VER=${SQLITE_VCS_BRANCH}
export SQLITE_VERSION=${SQLITE_VCS_BRANCH}
export SQLITE_VERSION=${SQLITE_VERSION:-"201708251543"}

# Install build deps
apk --no-cache --no-progress --virtual .libiconv-build-deps add g++ gcc musl-dev musl make autoconf automake wget
wget -nc http://www.sqlite.org/snapshot/sqlite-snapshot-${SQLITE_VERSION}.tar.gz -O /tmp/sqlite-${SQLITE_VERSION}.tar.gz

if [ -d /tmp/sqlite-${SQLITE_VERSION} ]; then
	rm -fR /tmp/sqlite-${SQLITE_VERSION}
fi

cd /tmp/sqlite-${SQLITE_VERSION}

./configure --prefix=/usr/local
make -j${CONTAINER_NB_CORES} && make install && libtool --finish /usr/local/lib

# Remove build deps
# apk --no-cache --no-progress del .sqlite-build-deps

# Cleanup
rm -r ${SQLITE_VCS_PATH}