#!/bin/bash -x

#import rvm config
source "$HOME/.rvm/scripts/rvm"
rvm use 'ruby-1.9.3-p0@brooklyn'

#kill any firefoxe turds
ps -ef | grep firefox-bin | grep -v grep | awk '{print $2}' | xargs -r kill -9

export RAILS_ENV=integration

# enable browser-based acceptance tests
export DISPLAY=:1
bin/rake db:migrate assets:precompile db:seed_fu

#start movie
if [ -n "$MAKE_MOVIE" ] ;  then
    echo 'making movie'
    nohup /usr/bin/ffmpeg -f x11grab -s sxga -r 30 -b 1200k -i :1.0 ./movies/$JOB_NAME-$BUILD_NUMBER.webm > /dev/null 2>&1 &
    /usr/bin/ffmpeg -f x11grab -s sxga -r 30 -b 1200k -i :1.0 ./movies/$JOB_NAME-$BUILD_NUMBER.webm > /dev/null 2>&1 &
fi

echo "we are retrying this many times: $RSPEC_RETRY"
bundle exec rspec ./acceptance --tag js --tag ~fails_in_jenkins --format documentation
#remember the exit code
export EXIT=$?

#clean up and push movie/logs to s3
if [ -n "$MAKE_MOVIE" ] ;  then
#if $MAKE_MOVIE ; then
    pkill ffmpeg
    /usr/bin/trickle -s -u 1000 /usr/local/bin/s3cmd --guess-mime-type --progress -P put ./movies/$JOB_NAME-$BUILD_NUMBER.webm s3://utahstreetlabs.com/test/brooklyn/acceptance-flakey/movies/ > /dev/null 2>&1
    mv ./movies/$JOB_NAME-$BUILD_NUMBER.webm /var/tmp/
    rm -f ./movies/$JOB_NAME-$BUILD_NUMBER.webm
fi

mv ./log/integration.log ./log/$JOB_NAME-$BUILD_NUMBER.log
/usr/bin/trickle -s -u 1000 /usr/bin/s3cmd -P put ./log/$JOB_NAME-$BUILD_NUMBER.log s3://utahstreetlabs.com/test/brooklyn/acceptance-flakey/logs/
rm -f ./log/$JOB_NAME-$BUILD_NUMBER.log

#make sure we fail in jenkins if the rspec failed
if [ $EXIT -ne 0 ] ; then exit 127 ; fi
