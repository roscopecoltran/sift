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

function ensure_golang_tools {
	for godep in ${GOLANG_TOOLS_GITHUB_URIS}; do
		GOLANG_BASENAME_DEP=$(basename $godep)
	    # GOLANG_DEP_EXECUTABLE=$(which $GOLANG_BASENAME_DEP) 
	    if [ -z "$(which $GOLANG_DEP_EXECUTABLE)" ]; then
	    	go get -v ${godep}
	    fi
	done  
}

ensure_golang_tools

