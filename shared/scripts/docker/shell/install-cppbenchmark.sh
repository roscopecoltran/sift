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
export CPPBENCHMARK_VCS_REPO=https://github.com/chronoxor/CppBenchmark.git
export CPPBENCHMARK_VCS_BRANCH=master
export CPPBENCHMARK_VCS_PATH=/tmp/CppBenchmark
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps with apk
apk --no-cache --no-progress --virtual .CppBenchmark-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export SRC_BUILD_DEPS="cmake"
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${COMMON_SCRIPT_DIR}/common/${dep}.sh ]; then
			chmod a+x ${COMMON_SCRIPT_DIR}/common/${dep}.sh
			${COMMON_SCRIPT_DIR}/common/${dep}.sh
		fi
		if [ -f ${COMMON_SCRIPT_DIR}/install-${dep}.sh ]; then
			echo "found ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
			chmod a+x ${COMMON_SCRIPT_DIR}/install-${dep}.sh
			${COMMON_SCRIPT_DIR}/install-${dep}.sh
		else
			echo "missing ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
		fi
	fi
done

# clean previous install
ensure_dir ${CPPBENCHMARK_VCS_PATH}

# Compile & Install 
git clone -b ${CPPBENCHMARK_VCS_BRANCH} --depth 1 -- ${CPPBENCHMARK_VCS_REPO} ${CPPBENCHMARK_VCS_PATH}

cd ${CPPBENCHMARK_VCS_PATH}/build
./unix.sh

# Remove build deps
# apk --no-cache --no-progress del .CppBenchmark-build-deps

# Cleanup
# rm -r ${CPPBENCHMARK_VCS_PATH}