###########################################################################
#		  
#  Build the image:                                               		  
#    $ docker build -t snk-sift:go1.9-alpine3.6 --no-cache . 				# longer but more accurate
#    $ docker build -t snk-sift:go1.9-alpine3.6 . 							# faster but increase mistakes
#                                                                 		  
#  Run the container:                                             		  
#    $ docker run -it --rm -v $(pwd)/shared:/shared -v $(pwd)/app:/app -p 4242:4242 snk-sift:go1.9-alpine3.6
#    $ docker run -d --name snk-sift -p 4242:4242 -v $(pwd)/app:/app -v $(pwd)/shared:/shared snk-sift:go1.9-alpine3.6
#                                                              		  
###########################################################################

## LEVEL1 ###############################################################################################################

# FROM frolvlad/alpine-glibc:alpine-3.6
FROM alpine:3.6
LABEL maintainer "Luc Michalski <michalski.luc@gmail.com>"

# apps
ARG GOSU_VERSION=${GOSU_VERSION:-"1.10"}

# default apks
ARG APK_RUNTIME=${APK_RUNTIME:-"git ca-certificates libssh2 openssl python3 libxml2 libxslt"}
ARG APK_BUILD=${APK_BUILD:-"python3-dev libxml2-dev libxslt-dev"}
ARG APK_INTERACTIVE=${APK_INTERACTIVE:-"nano bash tree jq"}

# custom apks
ARG APK_RUNTIME_CUSTOM=${APK_RUNTIME_CUSTOM:-""}
ARG APK_BUILD_CUSTOM=${APK_BUILD_CUSTOM:-""}
ARG APK_INTERACTIVE_CUSTOM=${APK_INTERACTIVE_CUSTOM:-""}

# golang
ENV GOPATH=/go

# app configuration
ENV PATH=${PATH}:${GOPATH}/bin \
	PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/" \
	SNK_REPO_PATH="/shared/data/repo"

# Install Gosu to /usr/local/bin/gosu
ADD https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 /usr/local/sbin/gosu

# Install runtime dependencies & create runtime user
RUN \
	chmod +x /usr/local/sbin/gosu \
	\
	&& apk add --update --no-cache --no-progress --virtual .container-runtime.deps ${APK_RUNTIME} ${APK_RUNTIME_CUSTOM} \
	&& apk add --update --no-cache --no-progress --virtual .container-build.deps ${APK_BUILD_CUSTOM} ${APK_BUILD_CUSTOM} \
	&& apk add --update --no-cache --no-progress --virtual .container-interactive.deps ${APK_INTERACTIVE} ${APK_INTERACTIVE_CUSTOM} \
	\
	&& adduser -D app -h /data -s /bin/sh

# Copy source code to the container & build it
COPY . /app
WORKDIR /app
# RUN ./shared/scripts/docker/build

# NSSwitch configuration file
COPY ./shared/scripts/docker/conf/nsswitch.conf /etc/nsswitch.conf

# Container configuration
VOLUME ["/data"]
EXPOSE 4242 6070 8888 8899

ENTRYPOINT ["/app/shared/scripts/docker/entrypoint"]
# CMD ["/bin/bash"]
# CMD ["/usr/local/sbin/gosu", "app", "/app/sniperkit"]
