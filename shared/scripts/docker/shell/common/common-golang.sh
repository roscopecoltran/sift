#!/bin/sh
set -x
set -e

clear
echo

export GOLANG_TOOLS_GITHUB_URIS=${GOLANG_TOOLS_GITHUB_URIS:-"github.com/gophergala/stk github.com/Masterminds/glide github.com/mitchellh/gox github.com/dahernan/godockerize"}

export GLIDE_TMP=/tmp/glide
export GLIDE_HOME=${GOPATH}/glide

if [ ! -d ${GLIDE_TMP} ]; then
	mkdir -p ${GLIDE_TMP}
fi
if [ ! -d ${GLIDE_HOME} ]; then
	mkdir -p ${GLIDE_HOME}
fi

function golang_ensure_builders {
	apk add --no-cache --no-progress --update --virtual .go.build-deps go make cmake musl-dev linux-headers sqlite-dev sqlite
	for godep in ${GOLANG_TOOLS_GITHUB_URIS}; do
		local GOLANG_BASENAME_DEP=$(basename $godep)
	    # GOLANG_DEP_EXECUTABLE=$(which $GOLANG_BASENAME_DEP) 
	    if [ -z "$(which $GOLANG_DEP_EXECUTABLE)" ]; then
	    	go get -v ${godep}
	    fi
	done  
}

function golang_cross_build {
	local GOLANG_BUILD_DIRS=${1:"."}
	apk add --no-cache --no-progress --update --virtual .go-cross.build-deps go-cross-darwin # go-cross-freebsd go-cross-openbsd 
	gox -verbose -os="linux darwin" -arch="amd64" -output="/shared/dist/{{.OS}}/{{.Dir}}/{{.Dir}}_{{.OS}}_{{.Arch}}" ${GOLANG_BUILD_DIRS}
}

golang_ensure_builders

