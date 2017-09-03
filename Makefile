PACKAGES := $(shell glide nv)
P ?= $(PACKAGES)

SHELL := /bin/bash -o pipefail

all: build test

deps:
	glide install
	which gometalinter || (go get -u github.com/alecthomas/gometalinter && gometalinter --install)

updatedeps: deps
	glide update

builddeps: clean

lint: clean
	gometalinter -j2 --deadline=120s -D gotype -D dupl -D errcheck -D gas $(PACKAGES)

build: builddeps
	go build -o seeker

buildstatic: builddeps
	CGO_ENABLED=0 go build -ldflags "-s -w" -o seeker_static

test: builddeps
	# Usage: make test (P=<package>)
	go test ./$(P)

testfull: build
	go test -v -race -cover $(PACKAGES) |tee testlog.out
	# Enforce 100% test coverage
	! cat testlog.out |grep ^ok |grep coverage: |grep -v 100.0%
	! grep "WARNING: DATA RACE" testlog.out
	@rm testlog.out

coverage: builddeps
	# Usage: make coverage P=<package>
	go test ./$(P) -v -covermode atomic -coverprofile=coverage.out
	go tool cover -html=coverage.out
	@rm -f coverage.out

run: build
	./seeker

clean:
	@rm -f seeker seeker_static
	@go clean

.PHONY: all deps updatedeps builddeps lint build buildstatic test testfull coverage run clean
