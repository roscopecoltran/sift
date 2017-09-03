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
export AMQPCPP_VCS_REPO=https://github.com/akalend/amqpcpp
export AMQPCPP_VCS_CLONE_BRANCH=master
export AMQPCPP_VCS_CLONE_DEPTH=1
export AMQPCPP_VCS_CLONE_PATH=/tmp/$(basename $AMQPCPP_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
# apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .curlpp-build-deps add rabbitmq-c rabbitmq-c-dev libcrypto1.0

if [ -d ${AMQPCPP_VCS_CLONE_PATH} ];then
	rm -fR ${AMQPCPP_VCS_CLONE_PATH}
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

# clean previous install
ensure_dir ${AMQPCPP_VCS_CLONE_PATH}

# Compile & Install libgit2 (v0.23)
git clone -b ${AMQPCPP_VCS_CLONE_BRANCH} --recursive --depth ${AMQPCPP_VCS_CLONE_DEPTH} -- ${AMQPCPP_VCS_REPO} ${AMQPCPP_VCS_CLONE_PATH}

mkdir -p ${AMQPCPP_VCS_CLONE_PATH}/build
cd ${AMQPCPP_VCS_CLONE_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${CONTAINER_NB_CORES} 
make install
# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

# Remove build deps
# apk --no-cache --no-progress del .curlpp-build-deps

# Cleanup
# rm -r ${AMQPCPP_VCS_CLONE_PATH}