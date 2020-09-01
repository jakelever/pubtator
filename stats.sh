#!/bin/bash
set -e

f=$1
fileCount=`grep Total $f | cut -f 2 -d ' '`
lastTime=`grep "Processing Time" $f | tail -n 1 | cut -f 4 -d ':' | cut -f 1 -d 's'`
filesProcessed=`grep "Processing Time" $f | tail -n 1 | grep -oP "000\d*" | tail -n 1 | awk ' { print $1+1} '`
baseFilename=`grep output $f | grep -oP "[\.\w]*.xml"`

perFile=`echo "$lastTime/$filesProcessed" | bc -l`

expectedHours=`echo "$perFile * $fileCount / (60*60)" | bc -l`

printf "Expected Time: %.1f | Per File: %.1f | File Count: %d | BioC: %s\n" $expectedHours $perFile $fileCount "$baseFilename"
