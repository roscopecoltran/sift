#!/bin/sh
set -x
set -e

clear
echo

export CONTAINER_MODE=${CONTAINER_MODE-"dev"}
export CONTAINER_NB_CORES=${CONTAINER_NB_CORES-$(getconf _NPROCESSORS_CONF)}
export CONTAINER_CMAKE_BUILD_TYPE=${CONTAINER_CMAKE_BUILD_TYPE-"Release"}

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

function rebuild_install_scripts_symlinks {
	clear
	echo 
	DEFAULT_SCRIPT_DIR="/app/shared/scripts/docker/shell"	
	DEFAULT_USR_LOCAL_SBIN_DIR="/usr/local/sbin"	
	chmod a+x ${DEFAULT_SCRIPT_DIR}/*.sh
	DOCKER_SCRIPTS=$(find ${DEFAULT_SCRIPT_DIR} -name "*.sh")
	for FILE_PATH in ${DOCKER_SCRIPTS}; do
		FILE_DIRNAME=$(dirname ${FILE_PATH})
		FILE_NAME=$(basename ${FILE_PATH})
		FILE_BASENAME=$(echo $FILE_NAME | cut -f 1 -d '.')
		echo "FILE_BASENAME: ${FILE_BASENAME} / FILE_NAME: ${FILE_NAME}"		
		echo 	
		if [ -f ${DEFAULT_USR_LOCAL_SBIN_DIR}/${FILE_BASENAME} ]; then
			rm -f ${DEFAULT_USR_LOCAL_SBIN_DIR}/${FILE_BASENAME}
		fi
		ln -s ${FILE_PATH} ${DEFAULT_USR_LOCAL_SBIN_DIR}/${FILE_BASENAME}
	done
}

export DOCKER_CONTAINER_HOST=$(ifconfig | grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" | grep -v 127.0.0.1 | awk '{ print $2 }' | cut -f2 -d: | head -n1)
