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
apk add --no-cache --no-progress --virtual .searx-adm-build-deps gcc make python3-dev musl-dev libxml2-dev libxslt-dev libffi-dev

# pip3 install searx

if [ -d /app/external/searx/admin ]; then
	rm -fR /app/external/searx/admin
fi

git clone --recursive --depth=1 https://github.com/kvch/searx-admin /app/external/searx/admin
cd /app/external/searx/admin

for p in /app/external/searx/admin/requirement*.txt; do pip3 install --no-cache --no-cache-dir -r $p; done
pip3 install --no-cache -e .

apk del --no-cache .searx-adm-build-deps
