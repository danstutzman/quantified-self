#!/bin/sh
cd `dirname $0`
cat create_database.sql | sqlite3 actions.sqlite3
cat sql | sqlite3 actions.sqlite3
