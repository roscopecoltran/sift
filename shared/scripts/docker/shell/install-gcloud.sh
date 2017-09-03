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
export PACKAGE_NAME=gcloud

# app vars
export GCLOUD_APP_ENGINES_PKGS="app-engine-go app-engine-python" #  app-engine-java

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
    if [ -f ${COMMON_SCRIPT_DIR}/common/${dep}.sh ]; then
      chmod a+x ${COMMON_SCRIPT_DIR}/common/${dep}.sh
      ${COMMON_SCRIPT_DIR}/common/${dep}.sh
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

# download and extract
wget -nc -O /tmp/google-cloud-sdk.zip https://dl.google.com/dl/cloudsdk/channels/rapid/google-cloud-sdk.zip
cd /tmp/
unzip /tmp/google-cloud-sdk.zip
rm -f  /tmp/google-cloud-sdk.zip

# install
google-cloud-sdk/install.sh
  --usage-reporting=true \
  --path-update=true \
  --bash-completion=true \
  --rc-path=/.bashrc \
  --additional-components \
   		alpha \
   		${GCLOUD_APP_ENGINES_PKGS} \
   		beta\
   		bigtable\
   		bq \
   		cloud-datastore-emulator \
   		docker-credential-gcr \
   		gcd-emulator \
   		gsutil \
   		kubectl \
   		pubsub-emulator

# clean
clean_all

# configure
google-cloud-sdk/bin/gcloud config set --installation component_manager/disable_update_check true
sed -i -- 's/\"disable_updater\": false/\"disable_updater\": true/g' /google-cloud-sdk/lib/googlecloudsdk/core/config.json
mkdir /.ssh

# Remove build deps
# apk --no-cache --no-progress del .${PACKAGE_NAME}-build-deps

# Cleanup
# rm -r ${PROJECT_VCS_CLONE_PATH}