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
export CMAKE_VCS_REPO=https://github.com/Kitware/cmake.git
export CMAKE_VCS_BRANCH=v3.9.1
export CMAKE_VCS_PATH=/tmp/cmake
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .cmake-build-deps add g++ gcc musl-dev make autoconf automake

ensure_dir ${CMAKE_VCS_PATH} 

# Compile & Install 
git clone -b ${CMAKE_VCS_BRANCH} --recursive --depth 1 -- ${CMAKE_VCS_REPO} ${CMAKE_VCS_PATH}

cd ${CMAKE_VCS_PATH}
./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .cmake-build-deps

# Cleanup
# rm -r ${CMAKE_VCS_PATH}