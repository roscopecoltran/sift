#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./docker/scripts/common.sh ]; then
	source ./docker/scripts/common.sh
fi

# Set temp environment vars
export CURLPP_VCS_REPO=https://github.com/jpbarrette/curlpp.git
export CURLPP_VCS_BRANCH=master
export CURLPP_VCS_PATH=/tmp/curlpp
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .curlpp-build-deps add g++ gcc musl-dev make autoconf automake curl-dev curl

if [ -d ${CURLPP_VCS_PATH} ];then
	rm -fR ${CURLPP_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${CURLPP_VCS_BRANCH} --depth 1 -- ${CURLPP_VCS_REPO} ${CURLPP_VCS_PATH}

mkdir -p ${CURLPP_VCS_PATH}/build
cd ${CURLPP_VCS_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${CONTAINER_NB_CORES} 
make install
# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .curlpp-build-deps

# Cleanup
rm -r ${CURLPP_VCS_PATH}