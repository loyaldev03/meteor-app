FROM ruby:2.4.2
ENV APP_HOME /app
ENV RAILS_ENV production
ENV RACK_ENV production
ENV RAILS_SERVE_STATIC_FILES true
RUN sed -i '/jessie-updates/d' /etc/apt/sources.list
RUN apt-get update -qq
RUN apt-get install -y apt-transport-https
RUN apt-get install -y --no-install-recommends build-essential
RUN apt-get update -qq && apt-get install -y apt-transport-https && apt-get install -y --no-install-recommends build-essential
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
RUN (bundle check || bundle install --without development)
ADD . $APP_HOME
# NOTE: the location of this file
# should be moved when the app is updated
RUN chmod +x script/docker/entrypoint.sh
ENTRYPOINT ["sh", "script/docker/entrypoint.sh"]
RUN bundle exec rake assets:precompile --trace
VOLUME /app/public
EXPOSE 3000
RUN chmod +x bin/rails
RUN chmod +x bin/delayed_job
RUN chmod +x rake_task_runner

CMD bundle exec bin/delayed_job start \
   && bundle exec rails s -b 0.0.0.0
