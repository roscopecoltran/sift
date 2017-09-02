#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./docker/scripts/common.sh ]; then
	source ./docker/scripts/common.sh
fi

# Set temp environment vars
export CPPSERVER_VCS_REPO=https://github.com/chronoxor/CppServer.git
export CPPSERVER_VCS_BRANCH=master
export CPPSERVER_VCS_PATH=/tmp/CppServer
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .CppServer-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export CPPSERVER_DEPS="cmake"
for dep in ${CPPSERVER_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./docker/scripts/install-${dep}.sh
		./docker/scripts/install-${dep}.sh
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
# apk --no-cache --no-progress del .CppServer-build-deps

# Cleanup
rm -r ${CPPSERVER_VCS_PATH}