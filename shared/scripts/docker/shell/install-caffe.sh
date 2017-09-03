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
export CAFFE_VCS_REPO=https://github.com/caffe2/caffe2.git
export CAFFE_VCS_BRANCH=v0.8.1
export CAFFE_VCS_PATH=/tmp/caffe2
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk add --update --no-cache --no-progress --allow-untrusted \
		--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --virtual .deepdetect-build-deps \
		g++ gcc musl-dev make rocksdb rocksdb-dev py3-numpy py-numpy-dev libtool python3 python3-dev \
		glog-dev glog py3-gflags eigen-dev eigen \
		opencv-dev opencv boost-dev boost-iostreams curl-dev \
		openssl-dev protobuf-c-dev protobuf-dev \
		openblas openblas-dev hdf5-dev hdf5 py3-protobuf \
		leveldb-dev leveldb snappy-dev snappy lmdb-dev lmdb

# clean previous install
ensure_dir ${CAFFE_VCS_PATH}

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

pip3 install --no-cache numpy

# Compile & Install 
git clone -b ${CAFFE_VCS_BRANCH} --depth 1 -- ${CAFFE_VCS_REPO} ${CAFFE_VCS_PATH}

mkdir -p ${CAFFE_VCS_PATH}/build
cd ${CAFFE_VCS_PATH}/build

# -DUSE_ROCKSDB=OFF 
cmake -DCMAKE_BUILD_TYPE=Release -DUSE_CUDA=OFF ..
make -j${CONTAINER_NB_CORES} 
make install

# Remove build deps
# apk --no-cache --no-progress del .caffe2-build-deps

# Cleanup
# rm -r ${CAFFE_VCS_PATH}