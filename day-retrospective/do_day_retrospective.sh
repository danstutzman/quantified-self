#!/bin/bash
cd `dirname $0`
TODAY=`date +'%Y-%m-%d'`
./parse-actions.rb $TODAY
open /Applications/LibreOffice.app logs.csv
