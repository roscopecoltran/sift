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
export MSGFLO_CPP_DEBUG=0
export MSGFLO_VCS_REPO=https://github.com/msgflo/msgflo-cpp
export MSGFLO_VCS_CLONE_BRANCH=master
export MSGFLO_VCS_CLONE_DEPTH=1
export MSGFLO_VCS_CLONE_PATH=/tmp/$(basename $MSGFLO_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .$(basename $MSGFLO_VCS_REPO)-build-deps add g++ gcc musl-dev make autoconf automake \
										libev libev-dev pkgconfig libtool py3-amqp 

if [ -d ${MSGFLO_VCS_CLONE_PATH} ];then
	rm -fR ${MSGFLO_VCS_CLONE_PATH}
fi

export SRC_BUILD_DEPS="cmake mosquitto pip3"
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
git clone -b ${MSGFLO_VCS_CLONE_BRANCH} --recursive --depth ${MSGFLO_VCS_CLONE_DEPTH} -- ${MSGFLO_VCS_REPO} ${MSGFLO_VCS_CLONE_PATH}

mkdir -p ${MSGFLO_VCS_CLONE_PATH}/build
cd ${MSGFLO_VCS_CLONE_PATH}/build
cmake -DCMAKE_BUILD_TYPE=Release ..
make -j${CONTAINER_NB_CORES} 
make install

pip3 install git+https://github.com/msgflo/msgflo-python

# Remove build deps
# apk --no-cache --no-progress del .$(basename $MSGFLO_VCS_REPO)-build-deps

# Cleanup
# rm -r ${MSGFLO_VCS_CLONE_PATH}