FROM alpine:3.17

ENV BUILD_PACKAGES curl curl-dev ruby-dev build-base
ENV RUBY_PACKAGES \
  ruby ruby-io-console \
  ruby-json ruby-etc ruby-bigdecimal \
  libffi-dev zlib-dev
RUN apk add --no-cache $BUILD_PACKAGES $RUBY_PACKAGES
RUN echo 'gem: --no-document' > /etc/gemrc && \
    gem install bundler

RUN bundle config --global silence_root_warning 1
WORKDIR /app

COPY Gemfile /app/Gemfile

RUN apk update \
    && apk add --no-cache --virtual build-deps \
    build-base \
    && bundle install \
    && apk del build-deps

RUN apk update \
    && apk add --no-cache \
    chromium \
    ffmpeg=5.1.2-r1 \
    font-noto \
    fontconfig \
    git \
    && wget https://noto-website.storage.googleapis.com/pkgs/NotoSansCJKjp-hinted.zip \
    && mkdir -p /usr/share/fonts/NotoSansCJKjp \
    && unzip NotoSansCJKjp-hinted.zip -d /usr/share/fonts/NotoSansCJKjp/ \
    && rm NotoSansCJKjp-hinted.zip \
    && fc-cache -fv

ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium-browser
