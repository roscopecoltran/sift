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
export GOOGLE_BENCHMARK_VCS_REPO=https://github.com/google/benchmark.git
export GOOGLE_BENCHMARK_VCS_BRANCH=master
export GOOGLE_BENCHMARK_VCS_PATH=/tmp/benchmark
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# clean previous install
ensure_dir ${GOOGLE_BENCHMARK_VCS_PATH}

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
# rm -r ${GOOGLE_BENCHMARK_VCS_PATH}