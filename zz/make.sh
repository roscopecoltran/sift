#!/bin/bash

set -e
set -x

apps=(app_scanner orchestrator port_scanner client)

build() {
    protoc -I ./zz/ ./zz/zz.proto --go_out=plugins=grpc:zz
    for app in "${apps[@]}"; do
	cd $app
    mkdir -p pb
    cp -r ../zz/zz.pb.go pb
    go build
	cd ..
    done
}

clean() {
    rm -f zz/zz.pb.go
    for app in "${apps[@]}"; do
	rm -f $app/$app
    done
}

case "$1" in
    clean)
	clean
	;;
    *)
	build
	;;
esac
