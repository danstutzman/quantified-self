#!/bin/bash
ruby -e "puts File.read('/Users/dstutzman/Desktop/zeodata.csv').gsub(\"\r\n\",'%0D%0A')" > zeodata.csv
curl -X POST -d @zeodata.csv http://192.168.0.66:4444/post_zeo_data
