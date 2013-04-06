#!/bin/bash

cd `dirname $0`
ruby ./get_facebook_froms.rb
while true; do
  echo "Waiting for new email..."
  ./idle_until_new_email.rb Records/Facebook
  if [ "$?" == "2" ]; then
    ruby ./get_facebook_froms.rb
  fi
done
