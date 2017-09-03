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
export LIBTAP_VCS_REPO=https://github.com/zorgnax/libtap.git
export LIBTAP_VCS_BRANCH=master
export LIBTAP_VCS_PATH=/tmp/libtap
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

if [ -d ${LIBTAP_VCS_PATH} ];then
	rm -fR ${LIBTAP_VCS_PATH}
fi

# Install build deps
apk --no-cache --no-progress --virtual .libtap-build-deps add g++ gcc musl-dev make autoconf automake boost-dev gtest-dev gtest

# clean previous install
ensure_dir ${LIBTAP_VCS_PATH}

# Compile & Install 
git clone -b ${LIBTAP_VCS_BRANCH} --depth 1 -- ${LIBTAP_VCS_REPO} ${LIBTAP_VCS_PATH}

mkdir -p ${LIBTAP_VCS_PATH}
cd ${LIBTAP_VCS_PATH}

# ANSI=1 make
make -j${CONTAINER_NB_CORES} 
make check
make install
# PREFIX=/usr make install

# Remove build deps
# apk --no-cache --no-progress del .libtap-build-deps

# Cleanup
# rm -r ${LIBTAP_VCS_PATH}