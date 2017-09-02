#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

export ALIASES_SCRIPT=$(find /app/shared -name "aliases.sh")
if [ -f ${ALIASES_SCRIPT} ]; then
	source ${ALIASES_SCRIPT}
fi

## #################################################################
## global env variables
## #################################################################

# ref. https://github.com/docker-library/python/blob/master/3.6/alpine3.6/Dockerfile#L105-L126

export PYTHON_PIP_VERSION=${PYTHON_PIP_VERSION:-"9.0.1"}

cd /tmp
wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'
python get-pip.py --disable-pip-version-check --no-cache-dir "pip==$PYTHON_PIP_VERSION"
pip --version
find /usr/local -depth \
	\( \
		\( -type d -a \( -name test -o -name tests \) \) \
		-o \
		\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
	\) -exec rm -rf '{}' +; 
rm -f get-pip.py

# ref.
#  - https://github.com/frol/docker-alpine-python3/blob/master/Dockerfile 
pip install --upgrade pip setuptools

# if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi