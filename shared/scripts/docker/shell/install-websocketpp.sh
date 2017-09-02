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
export WEBSOCKETPP_VCS_REPO=https://github.com/zaphoyd/websocketpp.git
export WEBSOCKETPP_VCS_BRANCH=master
export WEBSOCKETPP_VCS_PATH=/tmp/websocketpp
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .websocketpp-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export WEBSOCKETPP_DEPS="cmake"
for dep in ${WEBSOCKETPP_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
		./shared/scripts/docker/shell/install-${dep}.sh
	fi
done

if [ -d ${WEBSOCKETPP_VCS_PATH} ];then
	rm -fR ${WEBSOCKETPP_VCS_PATH}
fi

# Compile & Install libgit2 (v0.23)
git clone -b ${WEBSOCKETPP_VCS_BRANCH} --depth 1 -- ${WEBSOCKETPP_VCS_REPO} ${WEBSOCKETPP_VCS_PATH}

cd ${WEBSOCKETPP_VCS_PATH}/build
./unix.sh

# Remove build deps
# apk --no-cache --no-progress del .websocketpp-build-deps

# Cleanup
rm -r ${WEBSOCKETPP_VCS_PATH}