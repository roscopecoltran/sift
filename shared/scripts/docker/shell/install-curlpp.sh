#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
export COMMON_SCRIPT_DIR=$(dirname ${COMMON_SCRIPT})
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

# Set temp environment vars
export CURLPP_VCS_REPO=https://github.com/jpbarrette/curlpp
export CURLPP_VCS_CLONE_BRANCH=master
export CURLPP_VCS_CLONE_DEPTH=1
export CURLPP_VCS_CLONE_PATH=/tmp/$(basename $CURLPP_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .curlpp-build-deps add g++ gcc musl-dev make autoconf automake curl-dev curl

if [ -d ${CURLPP_VCS_PATH} ];then
	rm -fR ${CURLPP_VCS_PATH}
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
git clone -b ${CURLPP_VCS_CLONE_BRANCH} --recursive --depth ${CURLPP_VCS_CLONE_DEPTH} -- ${CURLPP_VCS_REPO} ${CURLPP_VCS_CLONE_PATH}

mkdir -p ${CURLPP_VCS_PATH}/build
cd ${CURLPP_VCS_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${CONTAINER_NB_CORES} 
make install
# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .curlpp-build-deps

# Cleanup
rm -r ${CURLPP_VCS_PATH}