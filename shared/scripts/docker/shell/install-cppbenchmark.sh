#!/bin/sh
set -x
set -e

clear
echo

# Set temp environment vars
export CPPBENCHMARK_VCS_REPO=https://github.com/chronoxor/CppBenchmark.git
export CPPBENCHMARK_VCS_BRANCH=master
export CPPBENCHMARK_VCS_PATH=/tmp/CppBenchmark
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps with apk
apk --no-cache --no-progress --virtual .CppBenchmark-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export CPPBENCHMARK_DEPS="cmake"
for dep in ${CPPBENCHMARK_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
		./shared/scripts/docker/shell/install-${dep}.sh
	fi
done

if [ -d ${CPPBENCHMARK_VCS_PATH} ];then
	rm -fR ${CPPBENCHMARK_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${CPPBENCHMARK_VCS_BRANCH} --depth 1 -- ${CPPBENCHMARK_VCS_REPO} ${CPPBENCHMARK_VCS_PATH}

cd ${CPPBENCHMARK_VCS_PATH}/build
./unix.sh

# Remove build deps
# apk --no-cache --no-progress del .CppBenchmark-build-deps

# Cleanup
rm -r ${CPPBENCHMARK_VCS_PATH}