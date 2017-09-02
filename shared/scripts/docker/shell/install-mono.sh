#!/bin/sh
set -x
set -e

clear
echo

if [ -f ./shared/scripts/docker/shell/common.sh ]; then
	source ./shared/scripts/docker/shell/common.sh
fi

export MONO_VERSION=${MONO_VERSION:-"4.8.0.495"}
export PAKET_VERSION=${PAKET_VERSION:-"5.92.0"}
export NUGET_VERSION=${NUGET_VERSION:-"4.1.0"}
export MONO_BUILD_PATH=${MONO_BUILD_PATH:-"/tmp/mono-src"}
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install build deps
apk add --no-cache --no-progress --virtual .mbe-build-deps g++ gcc wget ca-certificates musl-dev tar xz autoconf automake libtool gettext-dev zlib-dev

if [ -d ${MONO_BUILD_PATH} ]; then
	rm -fR ${MONO_BUILD_PATH}
fi

git clone --depth 1 --single-branch --branch mono-${MONO_VERSION} https://github.com/mono/mono.git ${MONO_BUILD_PATH}
cd ${MONO_BUILD_PATH}

for p in /app/docker/patches/*.patch; do echo "Applying $p"; patch -p1 < $p; done

./autogen.sh 	--prefix=/usr \
		        --sysconfdir=/etc \
		        --mandir=/usr/share/man \
		        --infodir=/usr/share/info \
		        --localstatedir=/var \
		        --disable-boehm \
		        --with-mcs-docs=no

make get-monolite-latest
make -j${CONTAINER_NB_CORES}
make install
rm -rf ${MONO_BUILD_PATH}

mcs --version
mono --version

cert-sync /etc/ssl/certs/ca-certificates.crt

rm /tmp/*
# apk del --no-cache .mbe-build-deps

# git clone --recursive -b cs7 https://github.com/usametov/Bookmarks-ETL /app/external/Bookmarks-ETL
# git clone --recursive -b cs7 https://github.com/usametov/tagsort-microservice
# https://github.com/usametov/MiGG-ng2
# https://github.com/usametov/gitmarks
# 