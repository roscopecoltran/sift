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
export NEWT_VCS_REPO=https://github.com/apache/mynewt-newt
export NEWT_VCS_BRANCH=mynewt_1_1_0_rc2_tag
export NEWT_VCS_PATH=${GOPATH}/src/mynewt.apache.org

# Install build deps
apk --no-cache --no-progress --virtual build-deps add go gcc musl-dev make cmake openssl-dev libssh2-dev 

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

# clean previous install
ensure_dir ${NEWT_VCS_PATH}

# Compile & Install newt (master)
git clone -b ${NEWT_VCS_BRANCH} --depth 1 -- ${NEWT_VCS_REPO} ${NEWT_VCS_PATH}
cd ${NEWT_VCS_PATH}

go get -v github.com/Masterminds/glide
export GLIDE_TMP=/tmp/glide
export GLIDE_HOME=${GOPATH}/glide

if [ ! -d ${GLIDE_TMP} ]; then
	mkdir -p ${GLIDE_TMP}
fi
if [ ! -d ${GLIDE_HOME} ]; then
	mkdir -p ${GLIDE_HOME}
fi

go get -v github.com/mitchellh/gox

if [ ! -f glide.yaml ]; then
	# rm -f glide.*
	glide create --non-interactive
fi

rm -fr vendor/github.com/Sirupsen
if [ ! -f glide.yaml ]; then find . -name glide.yaml -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi
if [ ! -f glide.lock ]; then find . -name glide.lock -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi
if [ -d ./vendor ]; then find ./vendor -type f -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi

if [ -f glide.yaml ]; then
	glide install --force 
fi

pwd

gox -verbose -os="linux" -arch="amd64" -output="/usr/local/sbin/{{.Dir}}" $(glide novendor)

# Cleanup
# # rm -r ${NEWT_VCS_PATH}