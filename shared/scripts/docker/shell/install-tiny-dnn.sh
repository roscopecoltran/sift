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
export TINY_DNN_VCS_REPO=https://github.com/tiny-dnn/tiny-dnn
export TINY_DNN_VCS_CLONE_BRANCH=master
export TINY_DNN_VCS_CLONE_DEPTH=1
export TINY_DNN_VCS_CLONE_PATH=/tmp/$(basename $TINY_DNN_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .$(basename $TINY_DNN_VCS_REPO)-build-deps add musl-dev make g++ gcc openblas opencv opencv-dev boost-dev

# clean previous install
ensure_dir ${TINY_DNN_VCS_CLONE_PATH}

export SRC_BUILD_DEPS=""
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${COMMON_SCRIPT_DIR}/common/${dep}.sh ]; then
			chmod a+x ${COMMON_SCRIPT_DIR}/common/${dep}.sh
			${COMMON_SCRIPT_DIR}/common/${dep}.sh
		fi
		if [ -f ${COMMON_SCRIPT_DIR}/install-${dep}.sh ]; then
			echo "found ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
			chmod a+x ${COMMON_SCRIPT_DIR}/install-${dep}.sh
			${COMMON_SCRIPT_DIR}/install-${dep}.sh
		else
			echo "missing ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
		fi
	fi
done

# Compile & Install 
git clone -b ${TINY_DNN_VCS_CLONE_BRANCH} --recursive --depth ${TINY_DNN_VCS_CLONE_DEPTH} -- ${TINY_DNN_VCS_REPO} ${TINY_DNN_VCS_CLONE_PATH}

mkdir -p ${TINY_DNN_VCS_CLONE_PATH}/build
cd ${TINY_DNN_VCS_CLONE_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=ON ..
make -j${CONTAINER_NB_CORES} 
make install
# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .$(basename $TINY_DNN_VCS_REPO)-build-deps

# Cleanup
# rm -r ${TINY_DNN_VCS_CLONE_PATH}