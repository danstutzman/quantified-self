#!/bin/sh
cd `dirname $0` # so can be executed from any directory
date "+%Y-%m-%d %H:%M:%S" | tr '\n' '	' >> actions.txt
echo "$@" >> actions.txt
