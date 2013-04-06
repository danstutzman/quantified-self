#!/bin/bash
cd `dirname $0`
echo "delete from hipchat_messages;" | sqlite3 ../data.sqlite3
curl -d "{}" http://localhost:4567/hipchat-message-received
