FROM ruby:2.4.2
ENV APP_HOME /app
ENV RAILS_ENV production
ENV RACK_ENV production
ENV RAILS_SERVE_STATIC_FILES true
RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential
RUN apt-get install -y mysql-client
RUN apt-get install -y libxml2-dev libxslt1-dev
RUN apt-get install -y libqtwebkit4 libqt4-dev xvfb
RUN apt-get install -y nodejs
RUN apt-get clean autoclean \
  && apt-get autoremove -y \
  && rm -rf \
    /var/lib/apt \
    /var/lib/dpkg \
    /var/lib/cache \
    /var/lib/log
RUN mkdir $APP_HOME
RUN mkdir $APP_HOME/tmp
WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
RUN (bundle check || bundle install --without development test)
ADD . $APP_HOME
# NOTE: the location of this file
# should be moved when the app is updated
ENTRYPOINT ["sh", "script/docker/entrypoint.sh"]
RUN bundle exec rake assets:precompile --trace
VOLUME /app/public
EXPOSE 3000
CMD ["script/rails", "s", "-b", "0.0.0.0"]
