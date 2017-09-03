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
export LIBCCV_VCS_REPO=https://github.com/liuliu/ccv
export LIBCCV_VCS_CLONE_BRANCH=unstable
export LIBCCV_VCS_CLONE_DEPTH=1
export LIBCCV_VCS_CLONE_PATH=/tmp/$(basename $LIBCCV_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .$(basename $LIBCCV_VCS_REPO)-build-deps add musl-dev make g++ gcc jpeg jpeg-dev libpng libpng-dev \
							gsl-dev gsl openblas openblas-dev

if [ -d ${LIBCCV_VCS_CLONE_PATH} ];then
	rm -fR ${LIBCCV_VCS_CLONE_PATH}
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
git clone -b ${LIBCCV_VCS_CLONE_BRANCH} --recursive --depth ${LIBCCV_VCS_CLONE_DEPTH} -- ${LIBCCV_VCS_REPO} ${LIBCCV_VCS_CLONE_PATH}

# lib
cd ${LIBCCV_VCS_CLONE_PATH}/lib 
./configure
make lib -j${CONTAINER_NB_CORES}

# bin
cd ${LIBCCV_VCS_CLONE_PATH}/bin
make -j${CONTAINER_NB_CORES}

# site
cd ${LIBCCV_VCS_CLONE_PATH}/site 
make source -j${CONTAINER_NB_CORES}

# tests
cd ${LIBCCV_VCS_CLONE_PATH}/test 
make -j${CONTAINER_NB_CORES}
make test

# Remove build deps
# apk --no-cache --no-progress del .$(basename $LIBCCV_VCS_REPO)-build-deps

# Cleanup
rm -r ${LIBCCV_VCS_CLONE_PATH}