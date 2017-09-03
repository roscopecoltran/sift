#!/bin/sh
set -x
set -e

clear
echo

export CONTAINER_MODE=${CONTAINER_MODE-"dev"}
export CONTAINER_NB_CORES=${CONTAINER_NB_CORES-$(getconf _NPROCESSORS_CONF)}
export CONTAINER_CMAKE_BUILD_TYPE=${CONTAINER_CMAKE_BUILD_TYPE-"Release"}

export CONTAINER_SCRIPT_DIR=${CONTAINER_SCRIPT_DIR:-"/app/shared/scripts/docker/shell"}
export COMMON_SCRIPT_DIR=${CONTAINER_SCRIPT_DIR}

export SRC_BUILD_DEPS=""
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${CONTAINER_SCRIPT_DIR}/helpers/${dep}.sh ]; then
			echo "found ${CONTAINER_SCRIPT_DIR}/helper-${dep}.sh"
			chmod a+x ${CONTAINER_SCRIPT_DIR}/helpers/${dep}.sh
			${CONTAINER_SCRIPT_DIR}/helpers/${dep}.sh
		else
			echo "missing ${CONTAINER_SCRIPT_DIR}/helper-${dep}.sh"
		fi
	fi
done

if [ -z "$(which make)" ]; then
	apk add --no-cache --no-progress --update make
fi

if [ -z "$(which echolor)" ]; then
	chmod a+x ${CONTAINER_SCRIPT_DIR}/helpers/*.sh
	make -f ${CONTAINER_SCRIPT_DIR}/helpers/Makefile all
fi

function ensure_dir {
	clear
	echo -e " "
	echo -e " **** ensure_dir $1 *** "
	if [ -d ${1} ]; then
		tree ${1}
		rm -fR ${1}
	fi
	mkdir -p ${1}
	echo -e " "
}

function check_generated_output {
	pwd
	ls -l 
}

function clean_all {
	CLEAN_DIRS_LIST=${1:-"/etc/ssl /usr/share/man /tmp/* /var/cache/apk/* /root/.npm /root/.node-gyp /root/.gnupg"}
	rm -Rf 	${CLEAN_DIRS_LIST}
}

function rebuild_install_scripts_symlinks {
	clear
	echo 	
	DEFAULT_SCRIPT_DIR=${CONTAINER_SCRIPT_DIR-"/app/shared/scripts/docker/shell"}
	DEFAULT_USR_LOCAL_SBIN_DIR=${DEFAULT_USR_LOCAL_SBIN_DIR-"/usr/local/sbin"}
	chmod a+x ${DEFAULT_SCRIPT_DIR}/*.sh
	DEFAULT_DOCKER_SCRIPTS=$(find ${DEFAULT_SCRIPT_DIR} -name "*.sh")
	for DOCKER_INSTALL_FILE_PATH in ${DEFAULT_DOCKER_SCRIPTS}; do
		DOCKER_INSTALL_FILE_DIRNAME=$(dirname ${DOCKER_INSTALL_FILE_PATH})
		DOCKER_INSTALL_FILE_NAME=$(basename ${DOCKER_INSTALL_FILE_PATH})
		DOCKER_INSTALL_FILE_BASENAME=$(echo $DOCKER_INSTALL_FILE_NAME | cut -f 1 -d '.')
		echo "DOCKER_INSTALL_FILE_BASENAME: ${DOCKER_INSTALL_FILE_BASENAME} / DOCKER_INSTALL_FILE_NAME: ${DOCKER_INSTALL_FILE_NAME}"		
		echo 	
		if [ -f ${DEFAULT_USR_LOCAL_SBIN_DIR}/${DOCKER_INSTALL_FILE_BASENAME} ]; then
			rm -f ${DEFAULT_USR_LOCAL_SBIN_DIR}/${DOCKER_INSTALL_FILE_BASENAME}
		fi
		if [ ! -f ${DEFAULT_USR_LOCAL_SBIN_DIR}/${DOCKER_INSTALL_FILE_BASENAME} ]; then		
			ln -s ${DOCKER_INSTALL_FILE_PATH} ${DEFAULT_USR_LOCAL_SBIN_DIR}/${DOCKER_INSTALL_FILE_BASENAME}
		fi
	done
}

export DOCKER_CONTAINER_HOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)

function link_analyze {
	# extract the protocol
	export current_link_proto="$(echo $1 | grep :// | sed -e's,^\(.*://\).*,\1,g')"
	# remove the protocol
	export current_link_url="$(echo ${1/$proto/})"
	# extract the user (if any)
	export current_link_user="$(echo $url | grep @ | cut -d@ -f1)"
	# extract the host
	export current_link_host="$(echo ${url/$user@/} | cut -d/ -f1)"
	# by request - try to extract the port
	export current_link_port="$(echo $host | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g' -e 's,[^0-9],,g')"
	# extract the path (if any)
	export current_link_path="$(echo $url | grep / | cut -d/ -f2-)"
	# provider
	export current_link_provider="$(echo $url | grep / | cut -d/ -f1)"
	# namespace
	export current_link_namespace="$(echo $url | grep / | cut -d/ -f2)"
	# reponame or project_name
	export current_link_interface="$(echo $url | grep / | cut -d/ -f3)"
	# package_uri
	export current_link_package_uri="${provider}/${namespace}/${interface}"
}

function link_analyze_print {
	echo
	local url=${1:-""}
	local branch=${2:-"master"}
	local dry=${3:-"y"}
	if [ "$url" != "" ]; then
		clear
		link_analyze $url
		echo
		echolor --green "args:"
		echolor --White "  url: $url"
		echolor --White "  dry: $dry"
		echo
		echolor --Yellow "raw:"
		echolor --White "  url: $url"
		echolor --White "  proto: $proto"
		echolor --White "  user: $user"
		echolor --White "  host: $host"
		echolor --White "  port: $port"
		echolor --White "  path: $path"
		echo
		echolor --Cyan "golang:"
		echolor --White "  provider:		$provider"
		echolor --White "  namespace:		$namespace"
		echolor --White "  interface:		$interface"
		echolor --White "  package_uri:		$package_uri"
		echo
	fi
	# echo "https://github.com/bstrds/4chdm/blob/42de90323321003998dcec7afced01e98825458d/4chdata/get" | sed 's/http\:\/\///g' | sed 's/https\:\/\///g'
	pwd
	echo
}

