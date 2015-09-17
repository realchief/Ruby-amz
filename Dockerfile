FROM ruby:2.2.2-slim

RUN apt-get update -qq && apt-get install --no-install-recommends -y \
  gcc                \
  make               \
  libmysqlclient-dev

RUN mkdir -p /app
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY . ./

EXPOSE 3000

CMD ["sidekiq", "-c", "1", "-q", "amz_bestsellers_green", "-r", "./lib/amz_bestsellers_bot/worker.rb"]
