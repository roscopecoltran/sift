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
export DLIB_VCS_REPO=https://github.com/davisking/dlib
export DLIB_VCS_CLONE_BRANCH=master
export DLIB_VCS_CLONE_DEPTH=1
export DLIB_VCS_CLONE_PATH=/tmp/$(basename $DLIB_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
export DLIB_CMAKE_ARGS=${DLIB_CMAKE_ARGS:-"-DUSE_AVX_INSTRUCTIONS=0"}

# Install build deps
apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .$(basename $DLIB_VCS_REPO)-build-deps add musl-dev make opencv opencv-dev \
									 g++ gcc openblas openblas-dev libpng libpng-dev boost-python boost-dev \
									 libjpeg-turbo libjpeg-turbo-dev jpeg jpeg-dev giflib giflib-dev

if [ -d ${DLIB_VCS_CLONE_PATH} ];then
	rm -fR ${DLIB_VCS_CLONE_PATH}
fi

export SRC_BUILD_DEPS=""
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
git clone -b ${DLIB_VCS_CLONE_BRANCH} --recursive --depth ${DLIB_VCS_CLONE_DEPTH} -- ${DLIB_VCS_REPO} ${DLIB_VCS_CLONE_PATH}

mkdir -p ${DLIB_VCS_CLONE_PATH}/build
cd ${DLIB_VCS_CLONE_PATH}/build

# c++
cmake -DCMAKE_BUILD_TYPE=Release ${DLIB_CMAKE_ARGS} ..
make -j${CONTAINER_NB_CORES} 
make install
# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# python
# https://github.com/davisking/dlib#compiling-dlib-python-api
cd ${DLIB_VCS_CLONE_PATH}
python3 setup.py install

# Remove build deps
# apk --no-cache --no-progress del .$(basename $DLIB_VCS_REPO)-build-deps

# Cleanup
rm -r ${DLIB_VCS_CLONE_PATH}