#!/bin/bash

cd `dirname $0`/..
while true; do
  echo "Waiting for new email..."
  bin/idle_until_new_email.rb
  if [ "$?" == "1" ]; then
    bin/getmail
  fi
done
