###########################################################################
#		  
#  Build the image:                                               		  
#    $ docker build -t sniperkit-sift:go1.9-alpine3.6 --no-cache . 			# longer but more accurate
#    $ docker build -t sniperkit-sift:go1.9-alpine3.6 . 					# faster but increase mistakes
#                                                                 		  
#  Run the container:                                             		  
#    $ docker run -it --rm -v $(pwd)/shared:/shared -v $(pwd)/app:/app -p 4242:4242 sniperkit-sift:go1.9-alpine3.6
#    $ docker run -d --name sniperkit -p 4242:4242 -v $(pwd)/app:/app -v $(pwd)/shared:/shared sniperkit-sift:go1.9-alpine3.6
#                                                              		  
###########################################################################

## LEVEL1 ###############################################################################################################

FROM frolvlad/alpine-glibc:alpine-3.6
# FROM alpine:3.6
LABEL maintainer "Luc Michalski <michalski.luc@gmail.com>"

ARG GOSU_VERSION=${GOSU_VERSION:-"1.10"}

ENV GOPATH=/go
ENV PATH=${PATH}:${GOPATH}/bin \
	PKG_CONFIG_PATH="/usr/lib/pkgconfig/:/usr/local/lib/pkgconfig/"

# Install Gosu to /usr/local/bin/gosu
ADD https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 /usr/local/sbin/gosu

# Install runtime dependencies & create runtime user
RUN chmod +x /usr/local/sbin/gosu \
 && apk --no-cache --no-progress add ca-certificates git libssh2 openssl bash nano tree jq python3 libxml2 libxslt libgit2 py3-numpy \
 && adduser -D app -h /data -s /bin/sh

# Copy source code to the container & build it
COPY . /app
WORKDIR /app
# RUN ./docker/scripts/build.sh

# NSSwitch configuration file
COPY ./docker/conf/nsswitch.conf /etc/nsswitch.conf

# App configuration
ENV SNK_REPO_PATH "/data/repo"

# Container configuration
VOLUME ["/data"]
EXPOSE 4242 6070

ENTRYPOINT ["/app/docker/scripts/entrypoint.sh"]
CMD ["/bin/bash"]
# CMD ["/usr/local/sbin/gosu", "app", "/app/sniperkit"]