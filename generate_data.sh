#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

if [ ! "$1" ]; then
    echo "Please specify an XLS/XLSX data file"
    exit 1
else
    data=$1

    FILES=$(find -E . -regex "./.*mls_.*xlsx?" | grep -v _site)
    for excel in $FILES
    do
	# find insists on a leading ./
	# I generally won't be providing such things when running this but
	# it's a good thing to watch out for when sanitizing FIXME TODO
	excel=$(echo $excel | perl -pe 's/^.\///;')

	# Would love to test if it's an xls/x properly but this is close enough
	if xlscat -i $excel 1>/dev/null 2>&1 ; then

	    # Prune file format
	    file=$(echo $excel | perl -pe 's/\.xlsx?$//;')

	    # Output file with same base name
	    csv=$(echo $file.csv)
	    # Convert XLS/XLSX to csv
	    xlscat -c $excel 1>/dev/null 2>&1 > $csv
	    echo "Generated $csv"

	    # Build the tables
	    table=$(echo $file.html)
	    if [ $excel == $data ]; then
		perl makeMLSTable.pl $csv $table
	    else
		perl makeMLSTable.pl $csv $table 1
	    fi
	    echo "Generated $table"

	    # Combine all the html pieces
	    if [ $excel == $data ]; then
		index=index.html
		cat top.html > $index
		cat $table >> $index
		cat bottom.html >> $index
	    else
		index=$file.index.html
		cat archive_top.html > $index
		cat $table >> $index
		cat archive_bottom.html >> $index
	    fi

	    # Properly indent file
	    emacs -batch $index --eval '(indent-region (point-min) (point-max) nil)' -f save-buffer 2>/dev/null
	    # Except not for index.html - WHY?
	    # FIXME TODO
	    # rm $index~

	    echo "Generated $index"
	    #echo "Site ready!"
	else
	    echo "$data is not a proper XLS/XLSX file"
	    exit 1
	fi
    done
fi
