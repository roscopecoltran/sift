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
export CMAKE_POLLY_VCS_REPO=https://github.com/ruslo/polly.git
export CMAKE_POLLY_VCS_BRANCH=master
export CMAKE_POLLY_VCS_PATH=/app/shared/helpers/$(basename $CMAKE_POLLY_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .$(basename $CMAKE_POLLY_VCS_PATH)-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

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

ensure_dir ${CMAKE_POLLY_VCS_PATH}

# Compile & Install libgit2 (v0.23)
git clone -b ${CMAKE_POLLY_VCS_BRANCH} --recursive --depth 1 -- ${CMAKE_POLLY_VCS_REPO} ${CMAKE_POLLY_VCS_PATH}

export PATH=$PATH:${CMAKE_POLLY_VCS_PATH}/bin

# Remove build deps
# apk --no-cache --no-progress del .$(basename $CMAKE_POLLY_VCS_PATH)-build-deps

# Cleanup
rm -r ${CMAKE_POLLY_VCS_PATH}