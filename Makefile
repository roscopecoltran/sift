
# determine platform
ifeq (Darwin, $(findstring Darwin, $(shell uname -a)))
  PLATFORM 		:= OSX
  GOLANG_OS 	:= darwin
else
  PLATFORM 		:= Linux
  GOLANG_OS 	:= linux
endif

APP_NAME 		:= sift
APP_BRANCH 		:= pkg
APP_DIST_DIR 	:= $(CURDIR)/dist

APP_PKGS 		:= $(shell go list ./... | grep -v /vendor/)
# APP_SRCS = $(shell git ls-files '*.go' | grep -v '^vendor/')
# GIT_BRANCH 		:= $(subst heads/,,$(shell git rev-parse --abbrev-ref HEAD 2>/dev/null))

test:
	@(go list ./... | grep -v "vendor/" | xargs -n1 go test -v -cover)

fmt:
	@(gofmt -w sift)

install:
	@cd $(CURDIR)/cmd/$(APP_NAME) && go install

dist: prepapre dist-linux dist-darwin dist-windows

dist-local: dist-$(GOLANG_OS)	

dist-linux: prepare
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o $(APP_DIST_DIR)/all/$(APP_NAME)_linux_amd64 -v github.com/roscopecoltran/sniperkit-$(APP_NAME)/cmd/$(APP_NAME)

dist-darwin: prepare
	@GOOS=darwin GOARCH=amd64 CGO_ENABLED=0 go build -o $(APP_DIST_DIR)/all/$(APP_NAME)_darwin_amd64 -v github.com/roscopecoltran/sniperkit-$(APP_NAME)/cmd/$(APP_NAME)

dist-windows: prepare
	@GOOS=windows GOARCH=amd64 CGO_ENABLED=0 go build -o $(APP_DIST_DIR)/all/$(APP_NAME)_windows_amd64.exe -v github.com/roscopecoltran/sniperkit-$(APP_NAME)/cmd/$(APP_NAME)

clean: glide-clean
	go clean && rm -rf $(APP_DIST_DIR)

git:
	@git checkout $(APP_BRANCH)
	@echo "GIT_BRANCH: $(GIT_BRANCH)"

gox: gox-install gox-xbuild

gox-install:
	@go get -v github.com/mitchellh/gox

gox-dist:
	@gox -verbose -os="darwin linux windows" -arch="amd64" -output="$(DIST_DIR)/{{.Os}}/{{.Dir}}_{{.Os}}_{{.Arch}}" $(APP_PKGS) # $(glide novendor)

glide: glide-create glide-install

glide-clean:
	@glide cc

glide-create:
	@if [ ! -f $(CURDIR)/glide.yaml ]; then glide create --non-interactive ; fi

glide-install:
	@if [ -f $(CURDIR)/glide.yaml ]; then glide install --strip-vendor ; fi

install-deps:
	@go get -v github.com/jteeuwen/go-bindata/...
	@go get -v github.com/elazarl/go-bindata-assetfs/...

logrus-fix:
	@if [ -d vendor/github.com/Sirupsen ]; then rm -fr vendor/github.com/Sirupsen ; fi
	@if [ -d vendor ]; then find vendor -type f -exec sed -i 's/Sirupsen/sirupsen/g' {} + ; fi

prepare: git
	@mkdir -p $(DIST_DIR), $(DIST_DIR)/darwin, $(DIST_DIR)/linux, $(DIST_DIR)/windows

travis: install-deps glide logrus-fix
	@echo "building..."
	@go build