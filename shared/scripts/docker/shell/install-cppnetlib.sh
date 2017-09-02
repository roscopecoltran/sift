#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./shared/scripts/docker/shell/common.sh ]; then
	source ./shared/scripts/docker/shell/common.sh
fi

# Set temp environment vars
export CPPNETLIB_VCS_REPO=https://github.com/cpp-netlib/cpp-netlib.git
export CPPNETLIB_VCS_BRANCH=master
export CPPNETLIB_VCS_PATH=/tmp/cpp-netlib
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

if [ -d ${CPPNETLIB_VCS_PATH} ];then
	rm -fR ${CPPNETLIB_VCS_PATH}
fi

# Install build deps
apk --no-cache --no-progress --virtual .cpp-netlib-build-deps add g++ gcc musl-dev make autoconf automake boost-dev gtest-dev gtest ninja pkgconf
# libmaxminddb libmaxminddb-dev

# Compile & Install libgit2 (v0.23)
git clone -b ${CPPNETLIB_VCS_BRANCH} --recursive --depth 1 -- ${CPPNETLIB_VCS_REPO} ${CPPNETLIB_VCS_PATH}

mkdir -p ${CPPNETLIB_VCS_PATH}/build
cd ${CPPNETLIB_VCS_PATH}/build

cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ ..
make -j${CONTAINER_NB_CORES} 
make install

# Remove build deps
# apk --no-cache --no-progress del .cpp-netlib-build-deps

# Cleanup
rm -r ${CPPNETLIB_VCS_PATH}