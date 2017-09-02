#!/bin/sh
set -x
set -e

clear
echo

# Install build deps
apk add --no-cache --no-progress --virtual .searx-build-deps gcc make python3-dev musl-dev libxml2-dev libxslt-dev libffi-dev

# pip3 install searx

if [ -d /app/external/searx ]; then
	rm -fR /app/external/searx
fi

git clone --recursive --depth=1 https://github.com/asciimoo/searx /app/external/searx
cd /app/external/searx

for p in /app/external/ast2vec/requirement*.txt; do pip3 install --no-cache --no-cache-dir -r $p; done
pip3 install --no-cache -e .

apk del --no-cache .searx-build-deps
