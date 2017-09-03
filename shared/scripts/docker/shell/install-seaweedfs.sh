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
export PROJECT_VCS_REPO=https://github.com/chrislusf/seaweedfs
export PROJECT_VCS_CLONE_BRANCH=unstable

export PROJECT_VCS_CLONE_DEPTH=1
export PROJECT_VCS_CLONE_PATH=/tmp/$(basename $PROJECT_VCS_REPO)
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .$(basename $PROJECT_VCS_REPO)-build-deps add musl musl-dev make g++ gcc

ensure_dir ${PROJECT_VCS_CLONE_PATH}

export SRC_BUILD_DEPS="golang libgit2"
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

# Compile & Install 
git clone -b ${PROJECT_VCS_CLONE_BRANCH} --recursive --depth ${PROJECT_VCS_CLONE_DEPTH} -- ${PROJECT_VCS_REPO} ${PROJECT_VCS_CLONE_PATH}

# lib
cd ${PROJECT_VCS_CLONE_PATH}/lib 
if [ ! -f glide.yaml ]; then
	glide create --non-interactive
fi

if [ -f glide.yaml ]; then
	glide install --force --strip-vendor
fi

# macros
make all
gox -verbose -os="linux" -arch="amd64" -output="/usr/local/sbin/{{.Dir}}" $(glide novendor)
# golang_cross_build `pwd`

# Remove build deps
# apk --no-cache --no-progress del .$(basename $PROJECT_VCS_REPO)-build-deps

# Cleanup
# rm -r ${PROJECT_VCS_CLONE_PATH}