#!/bin/sh
set -x
set -e

clear
echo

# Install build deps
apk add --no-cache --no-progress --virtual .sctk-build-deps gcc make python3-dev musl-dev libxml2-dev libxslt-dev libffi-dev

if [ -d /app/external/scancode-toolkit ]; then
	rm -fR /app/external/scancode-toolkit
fi

git clone --recursive --depth=1 https://github.com/nexB/scancode-toolkit /app/external/scancode-toolkit
cd /app/external/scancode-toolkit
pip3 install --no-cache -e .

# pip3 install scancode-toolkit
# apk del --no-cache .sctk-build-deps


