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
export NNG_VCS_REPO=https://github.com/nanomsg/nng.git
export NNG_VCS_BRANCH=master
export NNG_VCS_PATH=/tmp/nanomsg
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
# export MMCFLAGS="-std=c99 -Wall -Wextra -Werror -Wno-unused-parameter"

# Install build deps
apk --no-cache --no-progress --virtual .nanomsg-build-deps add g++ gcc musl-dev make autoconf automake pkgconfig libtool

if [ -d ${NNG_VCS_PATH} ];then
	rm -fR ${NNG_VCS_PATH}
fi

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

# Compile & Install libgit2 (v0.23)
git clone -b ${NNG_VCS_BRANCH} --depth 1 -- ${NNG_VCS_REPO} ${NNG_VCS_PATH}

mkdir -p ${NNG_VCS_PATH}/build
cd ${NNG_VCS_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Releaase ..
make -j${CONTAINER_NB_CORES}
make install

# Remove build deps
# apk --no-cache --no-progress del .nanomsg-build-deps

# Cleanup
rm -r ${NNG_VCS_PATH}