.PHONY: all deps build

# determine platform
ifeq (Darwin, $(findstring Darwin, $(shell uname -a)))
  MACHINE_LOCAL_PLATFORM := darwin
else
  MACHINE_LOCAL_PLATFORM := linux
endif	

# This Makefile is a simple example that demonstrates usual steps to build a binary that can be run in the same
# architecture that was compiled in. The "ldflags" in the build assure that any needed dependency is included in the
# binary and no external dependencies are needed to run the service.

### DOCKER_IMAGE ###############################################################

SNK_PROJECT_VERSION		?= ${SNK_SIFT_VERSION}

# TODO: Use real velues
DOCKER_REPO_OWNER		?= roscopecoltran
DOCKER_REPO_NAME		?= snk-sift
DOCKER_REPO_BRANCH		?= develop
DOCKER_PROJECT_DESC		?= Sniperkit Sift - A smarter scancode toolkit
DOCKER_PROJECT_URL		?= https://github.com/$(DOCKER_REPO_OWNER)/$(DOCKER_REPO_NAME)/tree/$(DOCKER_REPO_BRANCH)

DOCKER_IMAGE_TAG		?= $(SNK_SIFT_VERSION)
DOCKER_IMAGE_TAGS		?= latest
DOCKER_IMAGE_DEPENDENCIES 	+= $(SNK_SIFT_IMAGE)

### DOCKER_BASE_IMAGE #################################################################

# TODO: Use real values
BASE_IMAGE_NAME			?= $(DOCKER_PROJECT)/alpine:3.6
BASE_IMAGE_TAG			?= latest

### DOCKER_SNK_SIFT ##################################################################

# Simple CA image
SNK_SIFT_IMAGE_NAME		?= $(DOCKER_REPO_OWNER)/$(DOCKER_REPO_NAME)
SNK_SIFT_IMAGE_TAG		?= go1.9-alpine3.6
SNK_SIFT_IMAGE			?= $(SNK_SIFT_IMAGE_NAME):$(SNK_SIFT_IMAGE_TAG)

### GOLANG_SNK_SIFT ##################################################################
SNK_SIFT_VERSION		?= $(shell git describe --always --long --dirty --tags)
SNK_SIFT_DOMAIN			?= SnkSift

SNK_BIN_DIR 			?= $(PWD)/bin
SNK_BIN_NAME 			?= $(DOCKER_REPO_NAME)
SNK_BIN_NAME_REV		?= $(DOCKER_REPO_NAME)_${SNK_SIFT_VERSION}

SNK_DIST_DIR 			?= $(PWD)/dist

all: deps build

clear-output-dirs:
	@rm -fR $(SNK_BIN_DIR)
	@rm -fR $(SNK_DIST_DIR)

create-output-dirs:
	@mkdir -p $(SNK_BIN_DIR)
	@mkdir -p $(SNK_DIST_DIR)

deps:
	go get "github.com/svent/go-flags"
	go get "github.com/svent/go-nbreader"
	go get "github.com/roscopecoltran/sniperkit-sift"
	go get "golang.org/x/crypto"

build: create-output-dirs
	go build -a -ldflags="-X github.com/$(DOCKER_REPO_OWNER)/$(DOCKER_REPO_NAME)/core.$(SNK_SIFT_DOMAIN)Version=${SNK_SIFT_VERSION}" -o ${SNK_BIN_NAME} ./bin
	@echo "You can now use ./${BIN_NAME}"

### GOLANG #####################################################################

fmt:
	go fmt ./...

install-deps:
	go get github.com/jteeuwen/go-bindata/...
	go get github.com/elazarl/go-bindata-assetfs/...

### GOLANG_GLIDE ###############################################################

GLIDE_EXEC						:= $(which glide)
GLIDE_CREATE_AUTO 				:= True
GLIDE_CREATE_AUTO_ARG 			:= "--non-interactive"

GLIDE_INSTALL_FORCE 			:= True
GLIDE_INSTALL_FORCE_ARG 		:= "--force"
GLIDE_INSTALL_STRIP_VENDOR 		:= True
GLIDE_INSTALL_STRIP_VENDOR_ARG 	:= "--strip-vendor"

glide-get:
	@if [ ! -f $(GLIDE_EXEC) ]; then go get -v github.com/Masterminds/glide; fi

glide-create:
	@if [ ! -f glide.yaml ]; then glide create $(GLIDE_CREATE_AUTO_ARG); fi

glide-install: glide-get glide-create logrus-fix
	glide install $(GLIDE_INSTALL_FORCE_ARG) $(GLIDE_INSTALL_STRIP_VENDOR_ARG)

glide-prepare: glide-get glide-create glide-install

### GOLANG_GOX #################################################################

gox-cross: glide-get glide-get gox-darwin gox-linux gox-windows
# gox -verbose -os="linux darwin windows" -arch="amd64" -output="/shared/dist/{{.Dir}}/{{.Dir}}_{{.OS}}_{{.ARCH}}" $(glide novendor)

gox-all: glide-get gox-local gox-cross

gox-local: glide-install
	gox -verbose -os="$(MACHINE_LOCAL_PLATFORM)" -arch="amd64" -output="./bin/{{.Dir}}" $(glide novendor)

gox-darwin: glide-get glide-create
	gox -verbose -os="darwin" -arch="amd64" -output="./dist/{{.Dir}}/{{.Dir}}_{{.OS}}_{{.ARCH}}" $(glide novendor)

gox-linux: glide-get glide-create
	gox -verbose -os="linux" -arch="amd64" -output="./dist/{{.Dir}}/{{.Dir}}_{{.OS}}_{{.ARCH}}" $(glide novendor)

gox-windows: glide-get glide-create
	gox -verbose -os="windows" -arch="amd64" -output="./dist/{{.Dir}}/{{.Dir}}_{{.OS}}_{{.ARCH}}" $(glide novendor)

### GOLANG_FIX #################################################################

logrus-fix:
	@rm -fr vendor/github.com/Sirupsen
	@if [ ! -f glide.yaml ]; then find . -name glide.yaml -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi
	@if [ ! -f glide.lock ]; then find . -name glide.lock -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi
	@if [ -d ./vendor ]; then find ./vendor -type f -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi

### GOLANG_GENERATE ############################################################

generate: clean generate-models

generate-proto:
	protoc --gogofaster_out=. -Iproto -I$(GOPATH)/src proto/caffe2.proto

generate-models:
	go-bindata -nomemcopy -prefix builtin_models/ -pkg caffe2 -o builtin_models_static.go -ignore=.DS_Store  -ignore=README.md builtin_models/...

### GOLANG_CLEAN ###############################################################

clean-models:
	rm -fr builtin_models_static.go

clean-proto:
	rm -fr *pb.go

clean: clean-models

travis: install-deps glide-install logrus-fix generate
	echo "building..."
	go build

### GOLANG_GOM #################################################################

gom-get:
	go get -v github.com/mattn/gom

gom-install:
	gom gen gomfile

### DOCKER_VERSIONS ############################################################

DOCKER_VERSIONS		?= latest devel

### BUILD ######################################################################

# Docker image build variables
BUILD_VARS		+= SNK_PROJECT_VERSION

# Allows a change of the build/restore targets to the docker-tag if
# the development version is the same as the latest version
DOCKER_CI_TARGET	?= all
DOCKER_BUILD_TARGET	?= docker-build
DOCKER_REBUILD_TARGET	?= docker-rebuild

### DOCKER_EXECUTOR ############################################################

# Use the Docker Compose executor
DOCKER_EXECUTOR		?= compose

# Variables used in the Docker Compose file
COMPOSE_VARS		+= SERVER_CRT_HOST \
			   SNK_SIFT_IMAGE

# Certificate subject aletrnative names
# TODO: Use real values
SERVER_CRT_HOST		+= snk-sift.local

# Simple CA service name in the Docker Compose file
SNK_SIFT_SERVICE_NAME	?= $(shell echo $(SNK_SIFT_IMAGE_NAME) | sed -E -e "s|^.*/||" -e "s/[^[:alnum:]_]+/_/g")

# Simple CA container name
ifeq ($(DOCKER_EXECUTOR),container)
SNK_SIFT_CONTAINER_NAME ?= $(DOCKER_EXECUTOR_ID)_$(SNK_SIFT_SERVICE_NAME)
else ifeq ($(DOCKER_EXECUTOR),compose)
SNK_SIFT_CONTAINER_NAME ?= $(DOCKER_EXECUTOR_ID)_$(SNK_SIFT_SERVICE_NAME)_1
else ifeq ($(DOCKER_EXECUTOR),stack)
# TODO: Docker Swarm Stack executor
SNK_SIFT_CONTAINER_NAME ?= $(DOCKER_EXECUTOR_ID)_$(SNK_SIFT_SERVICE_NAME)_1
else
$(error Unknown Docker executor "$(DOCKER_EXECUTOR)")
endif

### MAKE_VARS ##################################################################

# Display the make variables
MAKE_VARS		?= GITHUB_MAKE_VARS \
			   BASE_IMAGE_MAKE_VARS \
			   DOCKER_IMAGE_MAKE_VARS \
			   BUILD_MAKE_VARS \
			   BUILD_TARGETS_MAKE_VARS \
			   EXECUTOR_MAKE_VARS \
			   CONFIG_MAKE_VARS \
			   SHELL_MAKE_VARS \
			   DOCKER_REGISTRY_MAKE_VARS \
			   DOCKER_VERSION_MAKE_VARS


define BUILD_TARGETS_MAKE_VARS
SNK_PROJECT_VERSION:	$(SNK_PROJECT_VERSION)

DOCKER_CI_TARGET:	$(DOCKER_CI_TARGET)
DOCKER_BUILD_TARGET:	$(DOCKER_BUILD_TARGET)
DOCKER_REBUILD_TARGET:	$(DOCKER_REBUILD_TARGET)
endef
export BUILD_TARGETS_MAKE_VARS

define CONFIG_MAKE_VARS
SNK_SIFT_IMAGE_NAME:	$(SNK_SIFT_IMAGE_NAME)
SNK_SIFT_IMAGE_TAG:	$(SNK_SIFT_IMAGE_TAG)
SNK_SIFT_IMAGE:	$(SNK_SIFT_IMAGE)

SERVER_CRT_HOST:	$(SERVER_CRT_HOST)
endef
export CONFIG_MAKE_VARS

### DOCKER_VERSION_TARGETS #####################################################


DOCKER_ALL_VERSIONS_TARGETS ?= build rebuild ci clean

### MAKE_TARGETS ###############################################################

# Build a new image and run the tests
.PHONY: docker-all
docker-all: docker-build docker-clean docker-start docker-wait docker-logs docker-test

# Build a new image and run the tests
.PHONY: ci
ci: $(DOCKER_CI_TARGET)
	@$(MAKE) clean

### BUILD_TARGETS ##############################################################

# Build a new image with using the Docker layer caching
.PHONY: build
build: $(DOCKER_BUILD_TARGET)
	@true

# Build a new image without using the Docker layer caching
.PHONY: rebuild
rebuild: $(DOCKER_REBUILD_TARGET)
	@true

### EXECUTOR_TARGETS ###########################################################

# Display the configuration file
.PHONY: config-file
config-file: display-config-file

# Display the make variables
.PHONY: makevars vars
makevars vars: display-makevars

# Remove the containers and then run them fresh
.PHONY: run up
run up: docker-up

# Create the containers
.PHONY: create
create: docker-create

# Start the containers
.PHONY: start
start: create docker-start

# Wait for the start of the containers
.PHONY: wait
wait: start docker-wait

# Display running containers
.PHONY: ps
ps: docker-ps

# Display the container logs
.PHONY: logs
logs: docker-logs

# Follow the container logs
.PHONY: logs-tail tail
logs-tail tail: docker-logs-tail

# Run shell in the container
.PHONY: shell sh
shell sh: start docker-shell

# Run the tests
.PHONY: test
test: start docker-test

# Run the shell in the test container
.PHONY: test-shell tsh
test-shell tsh:
	@$(MAKE) test TEST_CMD=/bin/bash

# Stop the containers
.PHONY: stop
stop: docker-stop

# Restart the containers
.PHONY: restart
restart: stop start

# Remove the containers
.PHONY: down rm
down rm: docker-rm

# Remove all containers and work files
.PHONY: clean
clean: docker-clean

### MK_DOCKER_IMAGE ############################################################

PROJECT_DIR		?= $(CURDIR)
MK_DIR			?= $(PROJECT_DIR)/scripts/mk
include $(MK_DIR)/docker.image.mk

################################################################################