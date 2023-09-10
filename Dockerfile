FROM alpine:3.17

ENV BUILD_PACKAGES curl curl-dev ruby-dev build-base
ENV RUBY_PACKAGES \
  ruby ruby-io-console \
  ruby-json ruby-etc ruby-bigdecimal \
  libffi-dev zlib-dev
RUN apk add --no-cache $BUILD_PACKAGES $RUBY_PACKAGES

WORKDIR /app

RUN apk update \
    && apk add --no-cache --virtual build-deps \
    build-base \
    && apk del build-deps

RUN apk update \
    && apk add --no-cache \
    ffmpeg \
    eyed3
