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
export RESTBED_VCS_REPO=https://github.com/Corvusoft/restbed.git
export RESTBED_VCS_BRANCH=master
export RESTBED_VCS_PATH=/tmp/restbed
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .restbed-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

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

if [ -d ${RESTBED_VCS_PATH} ];then
	rm -fR ${RESTBED_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${RESTBED_VCS_BRANCH} --depth 1 -- ${RESTBED_VCS_REPO} ${RESTBED_VCS_PATH}

cd ${RESTBED_VCS_PATH}/build
./unix.sh

# Remove build deps
# apk --no-cache --no-progress del .restbed-build-deps

# Cleanup
rm -r ${RESTBED_VCS_PATH}