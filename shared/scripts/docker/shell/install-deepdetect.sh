#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./shared/scripts/docker/shell/common.sh ]; then
	source ./shared/scripts/docker/shell/common.sh
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

for dep in ${DEEPDETECT_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
		./shared/scripts/docker/shell/install-${dep}.sh
	fi
done

if [ -d ${DEEPDETECT_VCS_PATH} ];then
	rm -fR ${DEEPDETECT_VCS_PATH}
fi

pip3 install --no-cache pyyaml

# Compile & Install libgit2 (v0.23)
git clone -b ${DEEPDETECT_VCS_BRANCH} --depth 1 -- ${DEEPDETECT_VCS_REPO} ${DEEPDETECT_VCS_PATH}

cd ${DEEPDETECT_VCS_PATH}

# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .deepdetect-build-deps

# Cleanup
rm -r ${DEEPDETECT_VCS_PATH}