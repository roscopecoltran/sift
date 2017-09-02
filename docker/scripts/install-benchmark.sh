#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./docker/scripts/common.sh ]; then
	source ./docker/scripts/common.sh
fi

# Set temp environment vars
export GOOGLE_BENCHMARK_VCS_REPO=https://github.com/google/benchmark.git
export GOOGLE_BENCHMARK_VCS_BRANCH=master
export GOOGLE_BENCHMARK_VCS_PATH=/tmp/benchmark
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

if [ -d ${GOOGLE_BENCHMARK_VCS_PATH} ];then
	rm -fR ${GOOGLE_BENCHMARK_VCS_PATH}
fi

# Install build deps
apk --no-cache --no-progress --virtual .benchmark-build-deps add g++ gcc musl-dev make autoconf automake boost-dev gtest-dev gtest

# Compile & Install libgit2 (v0.23)
git clone -b ${GOOGLE_BENCHMARK_VCS_BRANCH} --depth 1 -- ${GOOGLE_BENCHMARK_VCS_REPO} ${GOOGLE_BENCHMARK_VCS_PATH}

mkdir -p ${GOOGLE_BENCHMARK_VCS_PATH}/build
cd ${GOOGLE_BENCHMARK_VCS_PATH}/build

cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${CONTAINER_NB_CORES} 
make install

# Remove build deps
# apk --no-cache --no-progress del .benchmark-build-deps

# Cleanup
rm -r ${GOOGLE_BENCHMARK_VCS_PATH}