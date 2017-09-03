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

## #################################################################
## global env variables
## #################################################################

# Set temp environment vars
export PROJECT_VCS_URI=${PROJECT_VCS_URI:-"github.com/gpip/py-ccv"}
export PROJECT_VCS_BRANCH=${PROJECT_VCS_BRANCH:-"master"}
export PROJECT_VCS_CLONE_DEPTH=${PROJECT_VCS_CLONE_DEPTH:-"1"}
export PROJECT_VCS_CLONE_PATH=${PROJECT_VCS_CLONE_PATH:-"/app/$(basename $PROJECT_VCS_URI)"}

ensure_dir ${PROJECT_VCS_CLONE_PATH}

export SRC_BUILD_DEPS="libccv"
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

# Clone, Compile & Install
git clone -b ${PROJECT_VCS_BRANCH} --recursive \
		--depth ${PROJECT_VCS_CLONE_DEPTH} -- https://${PROJECT_VCS_URI} ${PROJECT_VCS_CLONE_PATH}

cd /tmp/ccv/lib
patch -p2 < ../../py-ccv/dynlib.patch
./configure
make libccv.so

cd ${PROJECT_VCS_CLONE_PATH}
ARCHFLAGS='-arch x86_64' INCDIR=/tmp/ccv/lib LIBDIR=/tmp/ccv/lib python setup.py install
# LDFLAGS="-L/tmp/ccv/lib" CFLAGS="-I/tmp/ccv/lib" pip install --no-cache --no-cache-dir git+https://github.com/gpip/py-ccv#egg=ccv

ls -l 
