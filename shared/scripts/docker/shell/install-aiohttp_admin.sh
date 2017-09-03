#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

## #################################################################
## global env variables
## #################################################################

# Set temp environment vars
export PROJECT_VCS_URI=${PROJECT_VCS_URI:-"github.com/aio-libs/aiohttp_admin.git"}
export PROJECT_VCS_BRANCH=${PROJECT_VCS_BRANCH:-"master"}
export PROJECT_VCS_CLONE_DEPTH=${PROJECT_VCS_CLONE_DEPTH:-"1"}
export PROJECT_VCS_CLONE_PATH=${PROJECT_VCS_CLONE_PATH:-"/app/aiohttp_admin"}

# clean previous install
ensure_dir ${PROJECT_VCS_CLONE_PATH}

# Clone, Compile & Install
git clone -b ${PROJECT_VCS_BRANCH} --recursive --depth ${PROJECT_VCS_CLONE_DEPTH} -- https://${PROJECT_VCS_URI} ${PROJECT_VCS_CLONE_PATH}

mkdir -p ${PROJECT_VCS_CLONE_PATH}
cd ${PROJECT_VCS_CLONE_PATH}

pip install --no-cache --no-cache-dir -e .
pip install -r /shared/conf.d/pip/requirements.dev.txt

ls -l 
