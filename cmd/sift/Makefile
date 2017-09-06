.PHONY: all deps build

# This Makefile is a simple example that demonstrates usual steps to build a binary that can be run in the same
# architecture that was compiled in. The "ldflags" in the build assure that any needed dependency is included in the
# binary and no external dependencies are needed to run the service.

# app vars
APP_NAME			?= sift
APP_NAME_UCFIRST	?= Sift
APP_VERSION			?= $(shell git describe --always --long --dirty --tags)
APP_VERSION_URI 	?= github.com/roscopecoltran/sniperkit-sift/sift
APP_LDFLAGS 		?= -ldflags="-X $(APP_VERSION_URI).$(APP_NAME_UCFIRST)Version=${APP_VERSION}"

# output vars
BIN_NAME			?= $(APP_NAME)_${APP_VERSION}

# Makefile targets
default: all ## default Makefile GNU target to trigger

all: deps build ## trigger all build targets to generate a locally usable executable file 

deps: ## fetch/import required dependencies by the current component
	@echo "no additional dependencies for this executable"

build: ## build the executable for the current local machine specifications
	@go build $(APP_LDFLAGS) -o ${BIN_NAME}
	@echo "You can now use ./${BIN_NAME}"

help: ## show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {sub("\\\\n",sprintf("\n%22c"," "), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)