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
name='the_silver_searcher'
version='0.33.0'
url="http://geoff.greer.fm/ag/releases/${name}-${version}.tar.gz"
dependencies='pcre xz'
path=/tmp/${name}
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .libmaxminddb-build-deps add g++ gcc musl-dev make autoconf automake pcre \
																	pcre-dev libtool xz-dev xz zlib zlib-dev


# clean previous install
ensure_dir ${path}

mkdir -p ${path}
cd ${path}

# Compile & Install the_silver_searcher
wget ${url}
tar xvf ${name}-${version}.tar.gz
cd ${name}-${version}

# --prefix="${PREFIX}"
PCRE_CFLAGS="-I${HOME}/.local/include" PCRE_LIBS="-L${HOME}/.local/lib -lpcre" ./configure --enable-zlib --enable-lzma

make -j${CONTAINER_NB_CORES}
make install # prefix="${STOW_PREFIX}/${name}-${version}"
ldconfig
# ldconfig -p | grep -q libmaxminddb.so

# Remove build deps
# apk --no-cache --no-progress del .libmaxminddb-build-deps

# Cleanup
# rm -r ${LIBMAXMINDDB_VCS_PATH}