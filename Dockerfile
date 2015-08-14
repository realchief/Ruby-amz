FROM ruby:2.2.2-slim

RUN apt-get update -qq && apt-get install --no-install-recommends -y gcc make libmysqlclient-dev

RUN mkdir /usr/src/amz-bestsellers-bot
WORKDIR /usr/src/amz-bestsellers-bot
ADD Gemfile /usr/src/amz-bestsellers-bot/Gemfile
RUN bundle install
ADD . /usr/src/amz-bestsellers-bot
