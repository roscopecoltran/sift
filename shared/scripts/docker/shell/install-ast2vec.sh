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
apk add --no-cache --no-progress --virtual .ast2vec-build-deps gcc make python3-dev musl-dev musl g++ libxml2-dev libxslt-dev libffi-dev

pip3 install git+https://github.com/bblfsh/client-python
# pip3 install ast2vec

# clean previous install
ensure_dir /app/external/ast2vec

git clone --recursive --depth=1 https://github.com/src-d/ast2vec /app/external/ast2vec
cd /app/external/ast2vec

for p in /app/external/ast2vec/requirement*.txt; do pip3 install --no-cache --no-cache-dir -r $p; done
pip3 install --no-cache -e .

apk del --no-cache .ast2vec-build-deps
