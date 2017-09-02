#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

# Install build deps
apk add --no-cache --no-progress --virtual .wmd-build-deps make python3-dev musl-dev libxml2-dev libxslt-dev libffi-dev

pip3 install git+https://github.com/src-d/wmd-relax

apk del --no-cache .wmd-build-deps