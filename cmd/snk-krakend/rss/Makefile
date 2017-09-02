.PHONY: all deps build

# This Makefile is a simple example that demonstrates usual steps to build a binary that can be run in the same
# architecture that was compiled in. The "ldflags" in the build assure that any needed dependency is included in the
# binary and no external dependencies are needed to run the service.

APP_VCS_OWNER			?= roscopecoltran
APP_VCS_PROVIDER		?= github.com
APP_VCS_REPO_URL		?= $(shell git config --get remote.origin.url)
APP_VCS_REPO_NAME		?= $(shell basename $(APP_VCS_REPO_URL))
APP_VCS_OWNER_URL		?= $(shell dirname $(APP_VCS_REPO_URL))
APP_VCS_OWNER_NAME		?= $(shell basename $(APP_VCS_OWNER_URL))

APP_BASENAME			?= $(shell basename $(PWD))
APP_DIRNAME 			?= $(shell dirname $(PWD))

APP_VERSION				?= $(shell git describe --always --long --dirty --tags)
APP_BIN_NAME			?= "$(APP_BASENAME)_$(APP_VERSION)"
APP_BIN_PREFIX_PATH		?= ./bin
APP_BIN_FILEPATH		?= $(APP_BIN_PREFIX_PATH)/$(APP_BASENAME)
APP_BIN_FILEPATH_REV	?= $(APP_BIN_PREFIX_PATH)/$(APP_BIN_NAME)

info:
	@echo " APP_VCS_PROVIDER: $(APP_VCS_PROVIDER)"

	@echo " APP_VCS_REPO_NAME: $(APP_VCS_REPO_NAME)"
	@echo " APP_VCS_OWNER_NAME: $(APP_VCS_OWNER_NAME)"

	@echo " APP_VCS_REPO_URL: $(APP_VCS_REPO_URL)"
	@echo " APP_VCS_OWNER_URL: $(APP_VCS_OWNER_URL)"

	@echo " APP_DIRNAME: $(APP_DIRNAME)"
	@echo " APP_BASENAME: $(APP_BASENAME)"
	@echo " APP_VERSION: $(APP_VERSION)"
	@echo " APP_BIN_NAME: $(APP_BIN_NAME)"

all: deps build

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

glide-deps: glide-get glide-create glide-install

### GOLANG_GOX #################################################################

gox-cross: glide-deps glide-get gox-darwin gox-linux gox-windows
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

### GOLANG_BUILD #################################################################

build: build-local build-rev

build-local: glide-deps
	go build -a -ldflags="-X $(APP_VCS_PROVIDER)/$(APP_VCS_OWNER)/$(APP_VCS_REPO_NAME)/core.$(APP_BASENAME)Version=${APP_VERSION}" -o $(APP_BIN_FILEPATH)
	@echo "You can now use $(APP_BIN_FILEPATH)"


build-rev: glide-deps
	go build -a -ldflags="-X $(APP_VCS_PROVIDER)/$(APP_VCS_OWNER)/$(APP_VCS_REPO_NAME)/core.$(APP_BASENAME)Version=${APP_VERSION}" -o $(APP_BIN_FILEPATH_REV)
	@echo "You can now use $(APP_BIN_FILEPATH_REV)"


