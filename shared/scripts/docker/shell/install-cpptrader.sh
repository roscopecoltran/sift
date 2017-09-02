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
export CPPSERVER_VCS_REPO=https://github.com/chronoxor/CppTrader.git
export CPPSERVER_VCS_BRANCH=master
export CPPSERVER_VCS_PATH=/tmp/CppTrader
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .CppTrader-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export SRC_BUILD_DEPS="cmake"
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${COMMON_SCRIPT_DIR}/install-${dep}.sh ]; then
			echo "found ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
			chmod a+x ${COMMON_SCRIPT_DIR}/install-${dep}.sh
			${COMMON_SCRIPT_DIR}/install-${dep}.sh
		else
			echo "missing ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
		fi
	fi
done

if [ -d ${CPPSERVER_VCS_PATH} ];then
	rm -fR ${CPPSERVER_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${CPPSERVER_VCS_BRANCH} --depth 1 -- ${CPPSERVER_VCS_REPO} ${CPPSERVER_VCS_PATH}
cd ${CPPSERVER_VCS_PATH}
git submodule update --init --recursive --remote
cd ${CPPSERVER_VCS_PATH}/build
./unix.sh

# Remove build deps
# apk --no-cache --no-progress del .CppTrader-build-deps

# Cleanup
rm -r ${CPPSERVER_VCS_PATH}