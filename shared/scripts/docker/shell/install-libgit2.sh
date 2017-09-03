#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

# Set temp environment vars
export LIBGIT2_VCS_REPO=${LIBGIT2_VCS_REPO:-"https://github.com/libgit2/libgit2"}
export LIBGIT2_VCS_CLONE_BRANCH=${LIBGIT2_VCS_CLONE_BRANCH:-"v0.25.0"}
export LIBGIT2_VCS_CLONE_DEPTH=${LIBGIT2_VCS_CLONE_DEPTH:-"1"}
export LIBGIT2_VCS_CLONE_PATH=${LIBGIT2_VCS_CLONE_PATH:-"/tmp/libgit2"}

# cmake args
export LIBGIT2_CMAKE_ARGS=${LIBGIT2_CMAKE_ARGS:-"-DBUILD_CLAR=off -DCMAKE_BUILD_TYPE=$CONTAINER_CMAKE_BUILD_TYPE"}

if [ -d ${LIBGIT2_VCS_CLONE_PATH} ]; then
	rm -fR ${LIBGIT2_VCS_CLONE_PATH}
fi

export SRC_BUILD_DEPS="cmake"
for dep in ${SRC_BUILD_DEPS}; do
	if [ -z "$(which $dep)" ]; then
		if [ -f ${COMMON_SCRIPT_DIR}/install-${dep}.sh ]; then
			echo "found ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
			chmod a+x ${COMMON_SCRIPT_DIR}/install-${dep}.sh
			${COMMON_SCRIPT_DIR}/install-${dep}.sh
		else
			echo "missing ${COMMON_SCRIPT_DIR}/install-${dep}.sh"
		fi
	fi
done

# Compile & Install libgit2
git clone -b ${LIBGIT2_VCS_CLONE_BRANCH} --recursive --depth ${LIBGIT2_VCS_CLONE_DEPTH} -- ${LIBGIT2_VCS_REPO} ${LIBGIT2_VCS_CLONE_PATH}

mkdir -p ${LIBGIT2_VCS_CLONE_PATH}/build
cd ${LIBGIT2_VCS_CLONE_PATH}/build

cmake ${LIBGIT2_CMAKE_ARGS} ..
cmake --build . --target install

# Cleanup
# rm -r ${LIBGIT2_VCS_CLONE_PATH}