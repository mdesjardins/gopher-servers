#!/bin/sh
#
# Runs a few simple tests against a running gopher server and compares the
# output against the expected output.
#

# defaults
HOST=Trs80.local
PORT=7070
EXPECTED_OUTPUT_DIR=./expected_output
TEMP_DIR=./tmp

. ./functions.sh

handle_args $@
echo "Testing $HOST on port $PORT, comparing output with files in $EXPECTED_OUTPUT_DIR"

cleanup

check
check 0/empty.txt
check 0/wasteland.txt
check I/tseliot.bmp
check g/tseliot.gif
check I/tseliot.jpg
check I/tseliot.png
check 5/tseliot.zip
check 5/tseliot.bmp.gz
check c/tseliot.ics
check 1/whitman
check 0/whitman/song.txt
check I/whitman/waltwhitman.bmp
check 4/whitman/waltwhitman.bmp.hqx
check g/whitman/waltwhitman.gif
check I/whitman/waltwhitman.jpg
check I/whitman/waltwhitman.png
check 5/whitman/waltwhitman.zip
check 0/this-selector-does-not-exist

