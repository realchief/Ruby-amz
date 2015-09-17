FROM ruby:2.2.2-slim

RUN apt-get update -qq && apt-get install --no-install-recommends -y gcc make libmysqlclient-dev

RUN mkdir /usr/src/amz-bestsellers-bot
WORKDIR /usr/src/amz-bestsellers-bot
ADD Gemfile /usr/src/amz-bestsellers-bot/Gemfile
ADD Gemfile.lock /usr/src/amz-bestsellers-bot/Gemfile.lock
RUN bundle install
ADD . /usr/src/amz-bestsellers-bot

EXPOSE 3000

CMD ["sidekiq", "-c", "1", "-q", "amz_bestsellers_green", "-r", "./lib/amz_bestsellers_bot/worker.rb"]
