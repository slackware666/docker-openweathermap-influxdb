FROM ruby:2.5
LABEL Maintainer=michael.ehrenreich@mailbox.org
RUN bundle config --global frozen 1
WORKDIR /usr/src/app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
CMD ['./openweathermap-influxdb.rb']