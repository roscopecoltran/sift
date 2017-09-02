#!/bin/sh
set -x
set -e

clear
echo

# Install build deps
apk add --no-cache --no-progress --virtual .njsy-build-deps nodejs-current nodejs-current-npm yarn

# apk del --no-cache .njsy-build-deps
