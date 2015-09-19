#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

if [ ! "$1" ]; then
    echo "Please specify an XLSX data file"
    exit 1
else
    data=$1
    # Would love to test if it's an xlsx properly but oh well
    xlscat -c $data > data_table.csv
fi
