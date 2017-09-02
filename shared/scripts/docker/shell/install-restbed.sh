#!/bin/sh
set -x
set -e

clear
echo

# Set temp environment vars
export RESTBED_VCS_REPO=https://github.com/Corvusoft/restbed.git
export RESTBED_VCS_BRANCH=master
export RESTBED_VCS_PATH=/tmp/restbed
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .restbed-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

export RESTBED_DEPS="cmake"
for dep in ${RESTBED_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
		./shared/scripts/docker/shell/install-${dep}.sh
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