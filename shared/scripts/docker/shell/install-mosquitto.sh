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
export MOSQUITTO_CPP_DEBUG=0
export MOSQUITTO_VCS_REPO=https://github.com/eclipse/mosquitto
export MOSQUITTO_VCS_CLONE_BRANCH=master
export MOSQUITTO_VCS_CLONE_DEPTH=1
export MOSQUITTO_VCS_CLONE_PATH=/tmp/$(basename $MOSQUITTO_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

function apk_install {
	# Install build deps
	apk --no-cache --no-progress --virtual .$(basename $MOSQUITTO_VCS_REPO)-build-deps add mosquitto mosquitto-clients
	mkdir -p /app/shared/conf.d/services/mosquitto /app/shared/data/mosquitto /app/shared/logs/mosquitto
	cp /etc/mosquitto/mosquitto.conf /app/shared/conf.d/services/mosquitto
	chown -R mosquitto:mosquitto /app/shared/conf.d/services/mosquitto
	chown -R mosquitto:mosquitto /app/shared/data/mosquitto
	chown -R mosquitto:mosquitto /app/shared/conf.d/services/mosquitto
	
	tree /app/shared/conf.d/services/mosquitto
	tree /app/shared/data/mosquitto
	tree /app/shared/conf.d/services/mosquitto
	mosquitto --help

	# Remove build deps
	# apk --no-cache --no-progress del .$(basename $MOSQUITTO_VCS_REPO)-build-deps
}

function src_install {
	# Install build deps
	apk --no-cache --no-progress --virtual .$(basename $MOSQUITTO_VCS_REPO)-build-deps add g++ gcc musl-dev openssl-dev libuuid docbook-xsl \
																				c-ares c-ares-dev python3-dev

	if [ -d ${MOSQUITTO_VCS_CLONE_PATH} ];then
		rm -fR ${MOSQUITTO_VCS_CLONE_PATH}
	fi

	export SRC_BUILD_DEPS="cmake"
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
	git clone -b ${MOSQUITTO_VCS_CLONE_BRANCH} --recursive --depth ${MOSQUITTO_VCS_CLONE_DEPTH} -- ${MOSQUITTO_VCS_REPO} ${MOSQUITTO_VCS_CLONE_PATH}

	mkdir -p ${MOSQUITTO_VCS_CLONE_PATH}/build
	cd ${MOSQUITTO_VCS_CLONE_PATH}/build
	cmake -DCMAKE_BUILD_TYPE=Release ..
	make -j${CONTAINER_NB_CORES} 
	make install
	# ./bootstrap && make -j${CONTAINER_NB_CORES} && make install

	# Remove build deps
	# apk --no-cache --no-progress del .$(basename $MOSQUITTO_VCS_REPO)-build-deps

	# Cleanup
	# rm -r ${MOSQUITTO_VCS_CLONE_PATH}
}

apk_install