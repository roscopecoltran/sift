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
export MS_BOND_VCS_REPO=https://github.com/Microsoft/bond
export MS_BOND_VCS_CLONE_BRANCH=master
export MS_BOND_VCS_CLONE_DEPTH=1
export MS_BOND_VCS_CLONE_PATH=/tmp/$(basename $MS_BOND_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .curlpp-build-deps add g++ gcc musl-dev make autoconf automake boost boost-dev boost-python \
																ccache wget zlib-dev zlib boost-thread clang clang-dev libtool \
																python3-dev boost-date_time ghc-dev ghc cabal


ensure_dir ${MS_BOND_VCS_CLONE_PATH}

export SRC_BUILD_DEPS="cmake"
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
git clone -b ${MS_BOND_VCS_CLONE_BRANCH} --recursive --depth ${MS_BOND_VCS_CLONE_DEPTH} -- ${MS_BOND_VCS_REPO} ${MS_BOND_VCS_CLONE_PATH}

mkdir -p ${MS_BOND_VCS_CLONE_PATH}/build
cd ${MS_BOND_VCS_CLONE_PATH}/build

cmake -DCMAKE_BUILD_TYPE=Release -DBOND_ENABLE_GRPC=FALSE ..
make -j${CONTAINER_NB_CORES} 
make install

# Remove build deps
# apk --no-cache --no-progress del .curlpp-build-deps

# Cleanup
# rm -r ${MS_BOND_VCS_CLONE_PATH}