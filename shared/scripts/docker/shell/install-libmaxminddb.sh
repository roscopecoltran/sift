#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./shared/scripts/docker/shell/common.sh ]; then
	source ./shared/scripts/docker/shell/common.sh
fi

# Set temp environment vars
export LIBMAXMINDDB_VCS_REPO=https://github.com/maxmind/libmaxminddb.git
export LIBMAXMINDDB_VCS_BRANCH=master
export LIBMAXMINDDB_VCS_PATH=/tmp/libmaxminddb
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .libmaxminddb-build-deps add g++ gcc musl-dev make autoconf automake perl-ipc-run3 libtool

if [ -d ${LIBMAXMINDDB_VCS_PATH} ];then
	rm -fR ${LIBMAXMINDDB_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${LIBMAXMINDDB_VCS_BRANCH} --depth 1 -- ${LIBMAXMINDDB_VCS_REPO} ${LIBMAXMINDDB_VCS_PATH}

cd ${LIBMAXMINDDB_VCS_PATH}
./bootstrap
./configure  --disable-tests
make -j${CONTAINER_NB_CORES}
make install
ldconfig
# ldconfig -p | grep -q libmaxminddb.so

# Remove build deps
# apk --no-cache --no-progress del .libmaxminddb-build-deps

# Cleanup
rm -r ${LIBMAXMINDDB_VCS_PATH}