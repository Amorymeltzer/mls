#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

if [ ! "$1" ]; then
    echo "Please specify an XLS/XLSX data file"
    exit 1
else
    data=$1

    FILES=$(find -E . -regex "./.*mls_.*xlsx?" | grep -v _site)
    for file in $FILES
    do
	# find insists on a leading ./
	# I generally won't be providing such things when running this but
	# it's a good thing to watch out for when sanitizing FIXME TODO
	file=$(echo $file | perl -pe 's/^.\///;')

	# Would love to test if it's an xls/x properly but this is close enough
	if xlscat -i $file 1>/dev/null 2>&1 ; then

	    # Output file with same base name
	    output=$(echo $file | perl -pe 's/(mls_.\d\d).xlsx?/\1.csv/;')
	    # Convert XLS/XLSX to csv
	    xlscat -c $file 1>/dev/null 2>&1 > $output
	    echo "Generated $output"

	    # Build the tables
	    table=$(echo $output | perl -pe 's/\.csv$/\1.html/;')
	    perl makeMLSTable.pl $output $table
	    echo "Generated $table"

	    # # Combine all the html pieces
	    # cat top.html > index.html
	    # cat table.html >> index.html
	    # cat bottom.html >> index.html

	    # # Properly indent file
	    # emacs -batch index.html --eval '(indent-region (point-min) (point-max) nil)' -f save-buffer 2>/dev/null

	    # echo "Generated index.html"
	    # echo "Site ready!"
	else
	    echo "$data is not a proper XLS/XLSX file"
	    exit 1
	fi
    done
fi
