#!/bin/sh
set -x
set -e

clear
echo

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

export LIBGIT2_DEPS="cmake"
for dep in ${LIBGIT2_DEPS}; do
	DEP_EXECUTABLE=$(which $dep) 
	if [ ! -f ${DEP_EXECUTABLE} ]; then
		cd /app 
		pwd
		chmod a+x ./shared/scripts/docker/shell/install-${dep}.sh
		./shared/scripts/docker/shell/install-${dep}.sh
	fi
done

# Compile & Install libgit2
git clone -b ${LIBGIT2_VCS_CLONE_BRANCH} --recursive --depth ${LIBGIT2_VCS_CLONE_DEPTH} -- ${LIBGIT2_VCS_REPO} ${LIBGIT2_VCS_CLONE_PATH}

mkdir -p ${LIBGIT2_VCS_PATH}/build
cd ${LIBGIT2_VCS_PATH}/build

cmake ${LIBGIT2_CMAKE_ARGS} ..
cmake --build . --target install

# Cleanup
rm -r ${LIBGIT2_VCS_PATH}