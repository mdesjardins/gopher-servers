#!/bin/sh
#
# Common functions for baselining and running tests.
#
function handle_args
{
    while getopts "t:h:p:e:" opt; do
        case "$opt" in
            h)
                HOST=$OPTARG
                ;;
            p)
                PORT=$OPTARG
                ;;
            e)
                EXPECTED_OUTPUT_DIR=$OPTARG
                ;;
            t)
                TEMP_DIR=$OPTARG
                ;;
        esac
    done
}

function cleanup
{
    rm -fr $TEMP_DIR
    mkdir $TEMP_DIR
}

function output_file_name
{
    RESOURCE=${1:-ROOT}
    /usr/bin/basename $RESOURCE
}

function get
{
    OUTFILE=`output_file_name $1`
    curl gopher://$HOST:$PORT/$1 -s --output $TEMP_DIR/$OUTFILE
}

function get_and_clean
{
    # I'm not a fan of gophernicus's use of null.host and port 1 on info
    # lines, I prefer to emit localhost and port. If using gophernicus as a
    # "reference" server, this fixes up gophernicus's output to be the way
    # I like it (which sorta defeats the purpose of a reference server but
    # oh well). Only use this to fetch menus.
    get $1
    OUTFILE=`output_file_name $1`

    # Fix the null.host
    sed -i.bak -e 's/null.host/$HOST/g' $TEMP_DIR/$OUTFILE
    rm $TEMP_DIR/$OUTFILE.bak

    # Fix the port number.
    sed -i.bak -e "s/1\(.\)$/$PORT\1/g" $TEMP_DIR/$OUTFILE
    rm $TEMP_DIR/$OUTFILE.bak
}

function check
{
    get $1
    FILENAME=`output_file_name $1`
    echo "Comparing $EXPECTED_OUTPUT_DIR/$FILENAME to $TEMP_DIR/$FILENAME ..."
    diff $EXPECTED_OUTPUT_DIR/$FILENAME $TEMP_DIR/$FILENAME
}
