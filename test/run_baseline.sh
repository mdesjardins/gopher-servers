#!/bin/sh
#
# Runs a few simple tests against a running baseline gopher server and
# stores the output in expected_output.
#

# defaults
HOST=Trs80.local
PORT=7070
TEMP_DIR=./expected_output

. ./functions.sh

handle_args $@
echo "Testing $HOST on port $PORT, saving output in $TEMP_DIR"

cleanup

get_and_clean
get 0/empty.txt
get 0/wasteland.txt
get I/tseliot.bmp
get g/tseliot.gif
get I/tseliot.jpg
get I/tseliot.png
get 5/tseliot.zip
get 5/tseliot.bmp.gz
get c/tseliot.ics
get 1/whitman
get 0/whitman/song.txt
get I/whitman/waltwhitman.bmp
get 4/whitman/waltwhitman.bmp.hqx
get g/whitman/waltwhitman.gif
get I/whitman/waltwhitman.jpg
get I/whitman/waltwhitman.png
get 5/whitman/waltwhitman.zip
get 0/this-selector-does-not-exist

