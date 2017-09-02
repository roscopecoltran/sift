#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./docker/scripts/common.sh ]; then
	source ./docker/scripts/common.sh
fi

# Set temp environment vars
export CAFFE2_VCS_REPO=https://github.com/caffe2/caffe2.git
export CAFFE2_VCS_BRANCH=v0.8.1
export CAFFE2_VCS_PATH=/tmp/caffe2
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install libgit2
if [ ! -f /usr/local/bin/cmake ]; then
	./docker/scripts/install-cmake.sh
fi

# Install build deps
apk add --update --no-cache --no-progress --allow-untrusted \
		--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --virtual .deepdetect-build-deps \
		g++ gcc musl-dev make rocksdb rocksdb-dev py3-numpy py-numpy-dev libtool python3 python3-dev \
		glog-dev glog py3-gflags eigen-dev eigen \
		opencv-dev opencv boost-dev boost-iostreams curl-dev \
		openssl-dev protobuf-c-dev protobuf-dev \
		openblas openblas-dev hdf5-dev hdf5 py3-protobuf \
		leveldb-dev leveldb snappy-dev snappy lmdb-dev lmdb

if [ -d ${CAFFE2_VCS_PATH} ];then
	rm -fR ${CAFFE2_VCS_PATH}
fi

pip3 install --no-cache numpy

# Compile & Install libgit2 (v0.23)
git clone -b ${CAFFE2_VCS_BRANCH} --depth 1 -- ${CAFFE2_VCS_REPO} ${CAFFE2_VCS_PATH}

mkdir -p ${CAFFE2_VCS_PATH}/build
cd ${CAFFE2_VCS_PATH}/build

# -DUSE_ROCKSDB=OFF 
cmake -DCMAKE_BUILD_TYPE=Release -DUSE_CUDA=OFF ..
make -j${CONTAINER_NB_CORES} 
make install

# Remove build deps
# apk --no-cache --no-progress del .caffe2-build-deps

# Cleanup
rm -r ${CAFFE2_VCS_PATH}