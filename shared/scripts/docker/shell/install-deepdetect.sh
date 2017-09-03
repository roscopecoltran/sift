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
export DEEPDETECT_VCS_REPO=https://github.com/beniz/deepdetect.git
export DEEPDETECT_VCS_BRANCH=master
export DEEPDETECT_VCS_PATH=/tmp/deepdetect
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .deepdetect-build-deps add 	g++ gcc musl-dev make autoconf automake \
																	glog-dev glog py3-gflags eigen-dev eigen \
																	opencv-dev opencv boost-dev boost-iostreams curl-dev \
																	openssl-dev protobuf-c-dev protobuf-dev \
																	openblas openblas-dev hdf5-dev hdf5 py3-protobuf \
																	leveldb-dev leveldb snappy-dev snappy lmdb-dev lmdb

# libcppnetlib-dev libcurlpp-dev libutfcpp-dev

export DEEPDETECT_DEPS="cmake pip3"

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

# clean previous install
ensure_dir ${DEEPDETECT_VCS_PATH}

pip3 install --no-cache pyyaml

# Compile & Install 
git clone -b ${DEEPDETECT_VCS_BRANCH} --depth 1 -- ${DEEPDETECT_VCS_REPO} ${DEEPDETECT_VCS_PATH}

cd ${DEEPDETECT_VCS_PATH}

# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .deepdetect-build-deps

# Cleanup
# rm -r ${DEEPDETECT_VCS_PATH}