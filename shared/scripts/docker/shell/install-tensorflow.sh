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
export TF_VCS_REPO=https://github.com/tensorflow/tensorflow.git
export TF_VCS_BRANCH=v1.3.0
export TF_VCS_CLONE_PATH=/tmp/tensorflow
export TF_VCS_CLONE_DEPTH=1
export TF_VERSION=${TF_VERSION:-"$TF_VCS_BRANCH"}

apk add --no-cache --no-progress --virtual .builddeps openjdk8 wget zip build-base bash python3-dev linux-headers 

if [ -d ${TF_VCS_CLONE_PATH} ]; then
	rm -fR ${TF_VCS_CLONE_PATH}
fi

git clone -b ${TF_VCS_BRANCH} --depth ${TF_VCS_CLONE_DEPTH} -- ${TF_VCS_REPO} ${TF_VCS_CLONE_PATH}

apk add --no-cache jemalloc libc6-compat
apk add --no-cache --virtual .builddeps.1 patch perl sed

pip3 install --no-cache wheel
pip3 install --no-cache --no-cache-dir pandas scipy scikit-learn keras tensorlayer pillow requests cython
pip3 install --no-cache --no-cache-dir pyzmq namedlist simplejson six "python-dateutil>2"
pip3 install --no-cache --no-cache-dir numpy scipy matplotlib bokeh
pip3 install --no-cache --no-cache-dir scikit-learn scikit-image
pip3 install --no-cache --no-cache-dir pandas networkx cvxpy seaborn
pip3 install --no-cache --no-cache-dir pillow sklearn
pip3 install --no-cache-dir supervisor

# echo | \
CC_OPT_FLAGS=-march=native \
PYTHON_BIN_PATH=/usr/bin/python \
TF_NEED_MKL=0 \
TF_NEED_VERBS=0 \  
TF_NEED_CUDA=0 \
TF_NEED_GCP=0 \
TF_NEED_JEMALLOC=1 \        
TF_NEED_HDFS=0 \
TF_NEED_OPENCL=0 \  
TF_ENABLE_XLA=0 \
./configure

./shared/scripts/docker/shell/install-bazel.sh

# build (option: --local_resources 3072,1.0,1.0)
bazel build -c opt ${EXTRA_BAZEL_ARGS} //tensorflow/tools/pip_package:build_pip_package
bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg
# install
pip3 install /tmp/tensorflow_pkg/tensorflow-${TENSORFLOW_VERSION}-cp35-cp35m-linux_x86_64.whl
pip3 install keras==${KERAS_VERSION}

# - hdf5
apk --no-cache add --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ hdf5
apk --no-cache add --virtual .builddeps.edge --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ hdf5-dev

pip3 install --no-cache h5py

## clean 
# apk del --no-cache .builddeps .builddeps.1 .builddeps.edge
apk del --no-cache .builddeps .builddeps.1 .builddeps.edge

find /usr/lib/python3.6 -name __pycache__ | xargs rm -r
rm -rf 	/root/.[acpw]* \
    	/tmp/bazel* \
    	/tmp/tensorflow* \
    	/usr/local/bin/bazel

# Cleanup
# rm -r ${TF_VCS_CLONE_PATH}