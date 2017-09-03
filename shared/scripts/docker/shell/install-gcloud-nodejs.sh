#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
export COMMON_SCRIPT_DIR=$(dirname ${COMMON_SCRIPT})
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

# Set temp environment vars
export PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"
export PACKAGE_NAME=node-gcloud

# Install build deps
# apk upgrade
apk --no-cache --no-progress --update \
	--repository http://dl-3.alpinelinux.org/alpine/edge/testing/ \
	--allow-untrusted \
	--virtual .${PACKAGE_NAME}-build-deps libc6-compat gcc g++ python make

ensure_dir ${PROJECT_VCS_CLONE_PATH}

export SRC_BUILD_DEPS=""
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${COMMON_SCRIPT_DIR}/common-${dep}.sh ]; then
		fi
		if [ -f ${COMMON_SCRIPT_DIR}/install-${dep}.sh ]; then
			echo "found ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
			chmod a+x ${COMMON_SCRIPT_DIR}/install-${dep}.sh
			${COMMON_SCRIPT_DIR}/install-${dep}.sh
		else
			echo "missing ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
		fi
	fi
done

npm install \@google-cloud/bigquery \
			\@google-cloud/datastore \
			\@google-cloud/pubsub \
			\@google-cloud/storage \
			bcrypt node-sass

rm -rf 	/etc/ssl \
		/usr/share/man \
		/tmp/* \
		/var/cache/apk/* \
		/root/.npm \
		/root/.node-gyp \
		/root/.gnupg \
		/usr/lib/node_modules/npm/man \
		/usr/lib/node_modules/npm/doc \
		/usr/lib/node_modules/npm/html

# Remove build deps
# apk --no-cache --no-progress del .${PACKAGE_NAME}-build-deps

# Cleanup
# rm -r ${PROJECT_VCS_CLONE_PATH}