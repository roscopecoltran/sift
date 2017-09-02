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
export XGBOOST_VCS_REPO=https://github.com/dmlc/xgboost
export XGBOOST_VCS_CLONE_BRANCH=master
export XGBOOST_VCS_CLONE_DEPTH=1
export XGBOOST_VCS_CLONE_PATH=/tmp/$(basename $XGBOOST_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
export XGBOOST_CMAKE_ARGS=${XGBOOST_CMAKE_ARGS:-"-DPLUGIN_UPDATER_GPU=OFF"}

# Install build deps
apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .$(basename $XGBOOST_VCS_REPO)-build-deps add musl-dev make g++ gcc openblas openblas-dev graphviz graphviz-dev \
															libexecinfo-dev doxygen zip boost-dev

if [ -d ${XGBOOST_VCS_CLONE_PATH} ];then
	rm -fR ${XGBOOST_VCS_CLONE_PATH}
fi

export SRC_BUILD_DEPS="cmake "
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
git clone -b ${XGBOOST_VCS_CLONE_BRANCH} --recursive --depth ${XGBOOST_VCS_CLONE_DEPTH} -- ${XGBOOST_VCS_REPO} ${XGBOOST_VCS_CLONE_PATH}

mkdir -p ${XGBOOST_VCS_CLONE_PATH}/build
cd ${XGBOOST_VCS_CLONE_PATH}/build

pip3 install --no-cache-dir cpplint 'pylint==1.4.4' 'astroid==1.3.6' 

# c++
cmake -DCMAKE_BUILD_TYPE=Release ${XGBOOST_CMAKE_ARGS} ..
make -j${CONTAINER_NB_CORES} 
make install
# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# python
cd ./python-package
python3 setup.py install --yes

# Remove build deps
# apk --no-cache --no-progress del .$(basename $XGBOOST_VCS_REPO)-build-deps

# Cleanup
rm -r ${XGBOOST_VCS_CLONE_PATH}