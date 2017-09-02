#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./shared/scripts/docker/shell/common.sh ]; then
	source ./shared/scripts/docker/shell/common.sh
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

# Compile & Install libgit2 (v0.23)
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
rm -r ${LIBTAP_VCS_PATH}