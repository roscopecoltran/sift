#!/bin/sh
set -x
set -e

clear
echo

# Set temp environment vars
export GOPATH=/go
export PATH=${PATH}:${GOPATH}/bin
export BUILDPATH=${GOPATH}/src/github.com/roscopecoltran/sniperkit-sift
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual build-deps add go gcc musl-dev make cmake openssl-dev libssh2-dev 
# libgit2-dev

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

if [ ! -f /usr/bin/pip3 ]; then
	./shared/scripts/docker/shell/install-pip3.sh
fi

# ./shared/scripts/docker/shell/install-ast2vec.sh

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

# Init go environment to build git2etcd
BUILDPATH_DIR=$(dirname ${BUILDPATH})
mkdir -p ${BUILDPATH_DIR}

if [ -d ${BUILDPATH} ]; then
	rm -fR ${BUILDPATH}
fi

ln -s /app ${BUILDPATH}

cd ${BUILDPATH}
if [ ! -f glide.yaml ]; then
	glide create --non-interactive
fi
if [ -f glide.yaml ]; then
	glide install --force --strip-vendor
fi

# go get -v
# go build luc
gox -verbose -os="linux" -arch="amd64" -output="/usr/local/sbin/{{.Dir}}" $(glide novendor)

# GOX_EXEC=$(which gox)
# alias goxi="$(GOX_EXEC) -verbose -os=linux -arch=amd64 -output=/usr/local/sbin/{{.Dir}} $(glide novendor)"

# Cleanup GOPATH
# # rm -r ${GOPATH}

# Remove build deps
# apk --no-cache --no-progress del build-deps