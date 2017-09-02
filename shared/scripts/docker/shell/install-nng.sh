#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./shared/scripts/docker/shell/common.sh ]; then
	source ./shared/scripts/docker/shell/common.sh
fi

# Set temp environment vars
export NNG_VCS_REPO=https://github.com/nanomsg/nng.git
export NNG_VCS_BRANCH=master
export NNG_VCS_PATH=/tmp/nanomsg
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .nanomsg-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

if [ -d ${NNG_VCS_PATH} ];then
	rm -fR ${NNG_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${NNG_VCS_BRANCH} --depth 1 -- ${NNG_VCS_REPO} ${NNG_VCS_PATH}

mkdir -p ${NNG_VCS_PATH}/build
cd ${NNG_VCS_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Releaase ..
make -j${CONTAINER_NB_CORES}
make install

# Remove build deps
# apk --no-cache --no-progress del .nanomsg-build-deps

# Cleanup
rm -r ${NNG_VCS_PATH}