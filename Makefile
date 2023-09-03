.PHONY: default server client deps fmt clean all release-all assets client-assets server-assets contributors
export GOPATH:=$(shell pwd)

BUILDTAGS=debug
default: all

deps: assets
	cd src/ngrok && go install -tags '$(BUILDTAGS)' -v ngrok/...

server: deps
	cd src/ngrok && go install -tags '$(BUILDTAGS)' ../ngrok/main/ngrokd

fmt:
	go fmt ngrok/...

client: deps
	cd src/ngrok && go install -tags '$(BUILDTAGS)' ngrok/main/ngrok

assets: client-assets server-assets

go-mod:
ifeq ($(wildcard src/ngrok/go.mod),)
	cd src/ngrok && go mod init ngrok && go mod tidy
endif

bin/go-bindata: go-mod
	GOOS="" GOARCH="" go install github.com/jteeuwen/go-bindata/go-bindata@latest

client-assets: bin/go-bindata
	bin/go-bindata -nomemcopy -pkg=assets -tags=$(BUILDTAGS) \
		-debug=$(if $(findstring debug,$(BUILDTAGS)),true,false) \
		-o=src/ngrok/client/assets/assets_$(BUILDTAGS).go \
		assets/client/...

server-assets: bin/go-bindata
	bin/go-bindata -nomemcopy -pkg=assets -tags=$(BUILDTAGS) \
		-debug=$(if $(findstring debug,$(BUILDTAGS)),true,false) \
		-o=src/ngrok/server/assets/assets_$(BUILDTAGS).go \
		assets/server/...

release-client: BUILDTAGS=release
release-client: client

release-server: BUILDTAGS=release
release-server: server

release-all: fmt release-client release-server

all: fmt client server

dist: DISTDIR=../../../../dist
dist: release-all
	@echo "Building servers..."
	cd src/ngrok/main/ngrokd && GOOS=darwin GOARCH=amd64 go build -tags release -o $(DISTDIR)/darwin/ngrokd ngrok/main/ngrokd
	cd src/ngrok/main/ngrokd && GOOS=windows GOARCH=amd64 go build -tags release -o $(DISTDIR)/windows/ngrokd.exe ngrok/main/ngrokd
	cd src/ngrok/main/ngrokd && GOOS=linux GOARCH=amd64 go build -tags release -o $(DISTDIR)/linux/ngrokd ngrok/main/ngrokd
	cd src/ngrok/main/ngrokd && GOOS=linux GOARCH=arm64 go build -tags release -o $(DISTDIR)/linux/ngrokd_arm64 ngrok/main/ngrokd
	@echo "Building clients..."
	cd src/ngrok/main/ngrok && GOOS=darwin GOARCH=amd64 go build -tags release -o $(DISTDIR)/darwin/ngrok ngrok/main/ngrok
	cd src/ngrok/main/ngrok && GOOS=windows GOARCH=amd64 go build -tags release -o $(DISTDIR)/windows/ngrok.exe ngrok/main/ngrok
	cd src/ngrok/main/ngrok && GOOS=linux GOARCH=amd64 go build -tags release -o $(DISTDIR)/linux/ngrok ngrok/main/ngrok
	cd src/ngrok/main/ngrok && GOOS=linux GOARCH=arm64 go build -tags release -o $(DISTDIR)/linux/ngrok_arm64 ngrok/main/ngrok

clean:
	go clean -i -r ngrok/...
	rm -rf src/ngrok/client/assets/ src/ngrok/server/assets/

contributors:
	@echo "Contributors to ngrok, both large and small:\n" > CONTRIBUTORS
	git log --raw | grep "^Author: " | sort | uniq | cut -d ' ' -f2- | sed 's/^/- /' | cut -d '<' -f1 >> CONTRIBUTORS
