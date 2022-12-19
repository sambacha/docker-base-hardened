# syntax=docker/dockerfile:1.4
# v2022.12.15

# SHA256SUM Ensures uniqueness
FROM buildpack-deps:bullseye-scm@sha256:5ac58be1d476acf3628a32650d82bf55247b34af110d455e2951bf7915e4fe22

ENV DEBIAN_FRONTEND=noninteractive
ENV GOLANG_VERSION 1.19

# ONBUILD Ensures we are dl deps thru proxy cache
ONBUILD ARG GOPROXY
ONBUILD ARG GONOPROXY
ONBUILD ARG GOPRIVATE
ONBUILD ARG GOSUMDB
ONBUILD ARG GONOSUMDB

#RUN GO111MODULE=on GOFLAGS=-mod=vendor go mod vendor
#RUN GO111MODULE=on GOFLAGS=-mod=vendor go mod tidy

#RUN GO111MODULE=on GOFLAGS=-mod=vendor CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
#    go build -o $GOLANG_APPLICATION ./cmd/$GOLANG_APPLICATION/entrypoint.go
    
    
# GCC for CGO
RUN DEBIAN_FRONTEND=noninteractivea apt-get update && apt-get install -qqy --assume-yes \
     gcc \
     libc6-dev \
     make; \
     rm -rf /var/lib/apt/lists/*
     apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false;


RUN curl -sSL https://go.dev/dl/go$GOLANG_VERSION.src.tar.gz | tar -v -C /usr/src -xz
RUN export PATH=$PATH:/usr/local/go/bin

#RUN cd /usr/src/go/src && ./make.bash --no-clean 2>&1

ENV PATH /usr/src/go/bin:$PATH


RUN mkdir -p /go/src /go/bin && chmod -R 777 /go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
WORKDIR /go

COPY go-wrapper /usr/local/bin/

RUN set -eux; \
	apt-get update; \
	apt-get install -y ca-certificates gosu; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

# Non-root user for security purposes.
#
# UIDs below 10,000 are a security risk, as a container breakout could result
# in the container being ran as a more privileged user on the host kernel with
# the same UID.
#
# Static GID/UID is also useful for chown'ing files outside the container where
# such a user does not exist.
RUN addgroup -g 10001 -S nonroot && adduser -u 10000 -S -G nonroot -h /home/nonroot nonroot


LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Golang" \
      org.label-schema.description="$INFO" \
      org.label-schema.url="https://$URL" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/$USR/$REPO.git" \
      org.label-schema.vendor="$USR" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"
