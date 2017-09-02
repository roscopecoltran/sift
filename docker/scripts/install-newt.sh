#!/bin/sh
set -x
set -e

clear
echo

# Set temp environment vars
export NEWT_VCS_REPO=https://github.com/apache/mynewt-newt
export NEWT_VCS_BRANCH=mynewt_1_1_0_rc2_tag
export NEWT_VCS_PATH=${GOPATH}/src/mynewt.apache.org

# Install build deps
apk --no-cache --no-progress --virtual build-deps add go gcc musl-dev make cmake openssl-dev libssh2-dev 

# Install libgit2
if [ ! -d /usr/local/include/git2 ]; then
	./docker/scripts/install-libgit2.sh
fi

if [ -d ${NEWT_VCS_PATH} ]; then
	rm -fR ${NEWT_VCS_PATH}
fi

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
# rm -r ${NEWT_VCS_PATH}