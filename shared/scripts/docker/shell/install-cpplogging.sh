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
export CPPLOGGING_VCS_REPO=https://github.com/chronoxor/CppLogging.git
export CPPLOGGING_VCS_BRANCH=master
export CPPLOGGING_VCS_PATH=/tmp/CppLogging
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .CppLogging-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export CPPLOGGING_DEPS="cmake"
for dep in ${CPPLOGGING_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
		./shared/scripts/docker/shell/install-${dep}.sh
	fi
done

# clean previous install
ensure_dir ${CPPLOGGING_VCS_PATH}

# Compile & Install 
git clone -b ${CPPLOGGING_VCS_BRANCH} --depth 1 -- ${CPPLOGGING_VCS_REPO} ${CPPLOGGING_VCS_PATH}

cd ${CPPLOGGING_VCS_PATH}/build
./unix.sh

# Remove build deps
# apk --no-cache --no-progress del .CppLogging-build-deps

# Cleanup
# rm -r ${CPPLOGGING_VCS_PATH}