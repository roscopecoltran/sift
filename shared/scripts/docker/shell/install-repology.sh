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
apk add --update --no-cache --no-progress gcc pkgconfig postgresql-dev 

if [ -d /app/external/repology ]; then
	rm -fR /app/external/repology
fi

pip3 install --no-cache --no-cache-dir Jinja2
pip3 install --no-cache --no-cache-dir PyYAML
pip3 install --no-cache --no-cache-dir coveralls
pip3 install --no-cache --no-cache-dir flake8
pip3 install --no-cache --no-cache-dir flake8-builtins
pip3 install --no-cache --no-cache-dir flake8-import-order
pip3 install --no-cache --no-cache-dir flake8-quotes
pip3 install --no-cache --no-cache-dir flask
pip3 install --no-cache --no-cache-dir lxml
pip3 install --no-cache --no-cache-dir psycopg2
pip3 install --no-cache --no-cache-dir pytidylib # uses newer libtidy installed below
pip3 install --no-cache --no-cache-dir requests
pip3 install --no-cache --no-cache-dir rubymarshal
pip3 install --no-cache --no-cache-dir voluptuous

git clone --recursive --depth=1 https://github.com/repology/repology /app/external/repology
cd /app/external/repology

# pip3 install --no-cache -e .
make			# test buidling C utils
make check		# check yaml schemas
make flake8 	# check python syntax
./repology-update.py --parse --initdb --database # fill database with test data

# ./repology-dump.py --help # smoke test bit
# coverage run --source="repology,repology-app" --omit="repology/fetcher/*" -m unittest discover # run unit tests with coverage

# pip3 install repology
# apk del --no-cache .relogy-build-deps



