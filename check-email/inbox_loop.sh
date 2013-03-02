#!/bin/bash

cd `dirname $0`
ruby ./get_inbox_froms.rb
while true; do
  echo "Waiting for new email..."
  ./idle_until_new_email.rb INBOX
  if [ "$?" == "2" ]; then
    ruby ./get_inbox_froms.rb
  fi
done
