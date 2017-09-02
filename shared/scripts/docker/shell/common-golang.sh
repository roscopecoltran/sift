#!/bin/sh
set -x
set -e

clear
echo

export GOLANG_TOOLS_GITHUB_URIS=${GOLANG_TOOLS_GITHUB_URIS:-"github.com/Masterminds/glide github.com/mitchellh/gox github.com/dahernan/godockerize"}

export GLIDE_TMP=/tmp/glide
export GLIDE_HOME=${GOPATH}/glide

if [ ! -d ${GLIDE_TMP} ]; then
	mkdir -p ${GLIDE_TMP}
fi
if [ ! -d ${GLIDE_HOME} ]; then
	mkdir -p ${GLIDE_HOME}
fi

function golang_ensure_builders {
	for godep in ${GOLANG_TOOLS_GITHUB_URIS}; do
		GOLANG_BASENAME_DEP=$(basename $godep)
	    # GOLANG_DEP_EXECUTABLE=$(which $GOLANG_BASENAME_DEP) 
	    if [ -z "$(which $GOLANG_DEP_EXECUTABLE)" ]; then
	    	go get -v ${godep}
	    fi
	done  
}

function golang_cross_build {
	GOLANG_BUILD_DIRS=${1:"."}
	apk add --no-cache --no-progress --update --virtual .go-cross.build-deps go-cross-darwin # go-cross-freebsd go-cross-openbsd 
	gox -verbose -os="linux darwin" -arch="i386 amd64" -output="/shared/dist/{{.Dir}}/{{.Dir}}_{{.OS}}_{{.Arch}}" ${GOLANG_BUILD_DIRS}
}

golang_ensure_builders

