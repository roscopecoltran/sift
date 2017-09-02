#!/bin/sh
set -x
set -e

clear
echo

# Install build deps
apk add --no-cache --no-progress --virtual sr-build-deps gcc make python3-dev musl-dev libxml2-dev libxslt-dev libffi-dev

pip3 install git+https://github.com/src-d/snippet-ranger

apk del --no-cache .sr-build-deps