#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

export PROJECT_VCS_URI=${PROJECT_VCS_URI:-"github.com/Onefootball/entity-rest-api"}
export PROJECT_VCS_BRANCH=${PROJECT_VCS_BRANCH:-"master"}

# Set temp environment vars
export GOPATH=/go
export PATH=${PATH}:${GOPATH}/bin
export BUILDPATH=${GOPATH}/src/${PROJECT_VCS_URI}
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk --no-cache --no-progress --virtual .etr.build-deps add go gcc musl-dev make openssl-dev libssh2-dev sqlite sqlite-dev sqlite-libs

# go helpers and deps
export COMMON_GOLANG_SCRIPT=$(find /app/shared -name "common-golang.sh")
if [ -f ${COMMON_GOLANG_SCRIPT} ]; then
	source ${COMMON_GOLANG_SCRIPT}
fi

ensure_dir ${BUILDPATH}
git clone --recursive --depth=1 -b master https://${PROJECT_VCS_URI} ${BUILDPATH}
cd ${BUILDPATH}

if [ ! -f glide.yaml ]; then
	glide create --non-interactive
fi

if [ -f glide.yaml ]; then
	glide install --force --strip-vendor
fi

# build
gox -verbose -os="linux" -arch="amd64" -output="/usr/local/sbin/{{.Dir}}" $(glide novendor)
if [ ${GOLANG_CROSS_BUILD} ]; then
	golang_cross_build "$(glide novendor)"
fi

# Cleanup GOPATH
# # rm -r ${BUILDPATH}

# Remove build deps
# apk --no-cache --no-progress del .etr.build-deps

