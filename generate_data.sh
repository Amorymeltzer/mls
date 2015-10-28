#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

if [ ! "$1" ]; then
    echo "Please specify an XLS/XLSX data file"
    exit 1
else
    data=$1

    arcindex="archive/index.html"
    cat archive/archive.index.top > $arcindex

    # Grab everything...
    FILES=$(find -E . -regex "./.*mls_.*xlsx?" | grep -v _site)
    # Sort files chronologically
    FILES=$(perl sortFiles.pl $FILES)

    # Die if no proper files can be found
    if [ -z "$FILES" ]; then
	echo "No valid files given!!!"
	exit
    fi

    for excel in $FILES
    do
	# find insists on a leading ./
	# I generally won't be providing such things when running this but
	# it's a good thing to watch out for when sanitizing FIXME TODO
	excel=$(echo $excel | perl -pe 's/^.\///;')

	# Would love to test if it's an xls/x properly but this is close enough
	if xlscat -i $excel &>/dev/null ; then

	    # Prune file format
	    file=$(echo $excel | perl -pe 's/\.xlsx?$//;')

	    # Output file with same base name
	    csv=$(echo $file.csv)
	    # Convert XLS/XLSX to csv
	    xlscat -c $excel &>/dev/null > $csv
	    echo "Generated $csv"

	    # Build the tables
	    table=$(echo $file.table)
	    if [ $excel == $data ]; then
		perl makeMLSTable.pl $csv $table
		echo "'Current as of' date no longer updated by default"
		echo "Use 'perl makeMLSTable.pl -u $csv $table' to update index"
	    else
		perl makeMLSTable.pl $csv $table 1
	    fi
	    echo "Generated $table"

	    # Combine all the html pieces
	    if [ $excel == $data ]; then
		index=index.html
		top=top.html
		bottom=bottom.html
	    else
		index=$file.html
		top=archive_top.html
		bottom=archive_bottom.html
		perl makeArchiveIndex.pl $file $arcindex
	    fi

	    cat $top > $index
	    cat $table >> $index
	    cat $bottom >> $index

	    # Properly indent file
	    emacs -batch $index --eval '(indent-region (point-min) (point-max) nil)' -f save-buffer 2>/dev/null

	    # Except not for index.html - WHY? FIXME TODO
	    # rm $index~


	    echo "Generated $index"

	else
	    echo "$data is not a proper XLS/XLSX file"
	    exit 1
	fi
    done
    cat archive/archive.index.bottom >> $arcindex

    echo
    echo "Site ready!"
fi
