#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

if [ ! "$1" ]; then
    echo "Please specify an XLS/XLSX data file"
    exit 1
else
    data=$1
    # Would love to test if it's an xlsx properly but this is close enough
    if xlscat -i $data 1>/dev/null 2>&1 ; then
	if [ ! $2 ]; then
	    output=data_table.csv
	else
	    output=$2
	fi
	xlscat -c $data 1>/dev/null 2>&1 > $output
	echo "Generated $output"

	perl makeMLSTable.pl $output table.html
	echo "Generated table.html"

	cat top.html > index.html
	cat table.html >> index.html
	cat bottom.html >> index.html

	echo "Generated index.html"
	echo "Site ready!"
    else
	echo "$data is not a proper XLS/XLSX file"
	exit 1
    fi
fi
