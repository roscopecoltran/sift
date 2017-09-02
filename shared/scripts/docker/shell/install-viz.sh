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
apk add --no-cache --no-progress --virtual .viz-build-deps python3-dev

if [ -d /app/external/viz ]; then
	rm -fR /app/external/viz
fi

git clone --recursive --depth=1 https://github.com/donnemartin/viz /app/external/viz
cd /app/external/viz

for p in /app/external/gitsome/requirement*.txt; do pip3 install --no-cache --no-cache-dir -r $p; done
pip3 install --no-cache -e .

# pip3 install git+https://github.com/bblfsh/client-python
# pip3 install ast2vec

# apk del --no-cache .viz-build-deps


