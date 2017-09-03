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
apk add --no-cache --no-progress --virtual .gits-build-deps python3-dev

# clean previous install
ensure_dir /app/external/gitsome

git clone --recursive --depth=1 https://github.com/donnemartin/gitsome /app/external/gitsome
cd /app/external/gitsome

for p in /app/external/gitsome/requirement*.txt; do pip3 install --no-cache --no-cache-dir -r $p; done
pip3 install --no-cache -e .

# pip3 install git+https://github.com/bblfsh/client-python
# pip3 install ast2vec

# apk del --no-cache .gits-build-deps


