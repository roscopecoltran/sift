#!/bin/sh
set -x
set -e

clear
echo

export COMMON_SCRIPT=$(find /app/shared -name "common.sh")
if [ -f ${COMMON_SCRIPT} ]; then
	source ${COMMON_SCRIPT}
fi

export BAZEL_VERSION=${BAZEL_VERSION:-"0.5.4"}
export JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk"
export LOCAL_RESOURCES="2048,.5,1.0"

# Install build deps
# apk --no-cache --no-progress --virtual .bazel-build-deps add bash 
# apk add --no-cache --update --no-progress python3 python3-dev python3-tkinter py3-numpy py3-numpy-f2py freetype libpng libjpeg-turbo imagemagick graphviz
# apk add --no-cache --no-progress --virtual .cmake-build-deps g++ gcc musl-dev make autoconf automake py-numpy-dev rsync swig libjpeg-turbo-dev freetype-dev 

if [ -d /tmp/bazel ];then
	rm -fR /tmp/bazel
fi
mkdir -p /tmp/bazel

wget -q -O /tmp/bazel-dist.zip https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip
unzip -q -d /tmp/bazel /tmp/bazel-dist.zip

cd /tmp/bazel

# add -fpermissive compiler option to avoid compilation failure 
sed -i -e '/"-std=c++0x"/{h;s//"-fpermissive"/;x;G}' tools/cpp/cc_configure.bzl

# add '#include <sys/stat.h>' to avoid mode_t type error 
sed -i -e '/#endif  \/\/ COMPILER_MSVC/{h;s//#else/;G;s//#include <sys\/stat.h>/;G;}' third_party/ijar/common.h

# # add jvm opts for circleci
# && sed -i -E 's/(jvm_opts.*\[)/\1 "-Xmx1024m",/g' src/java_tools/buildjar/BUILD \
bash compile.sh
cp output/bazel /usr/local/bin/