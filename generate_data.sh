#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

function get_help {
    cat <<END_HELP

Usage: $1 -i <current_season.xlsx> [-ulh]

  -i		Specify input XLS/XLSX data file.  Required.
  -u		Pass -u to makeMLSTable.pl (updates 'current as of' date)
  -l		Pass -l to makeMLSTable.pl (latest, not current, season)
  -h		this help
END_HELP
}

while getopts 'i:ulhH?' opt; do
    case $opt in
	i) input=$OPTARG;;
	u) upDate='-u';;
	l) latest='-l';;
	h) get_help $0
	   exit 0;;
	:) printf "Option -"$opt" requires an argument, try $0 -h\n" >&2
           exit 1;;
    esac
done


if [ ! $input ]; then
    echo "Please specify an XLS/XLSX data file"
    exit 1
else
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
	    if [ $excel == $input ]; then
		perl makeMLSTable.pl $upDate $latest $csv $table
	    else
		perl makeMLSTable.pl -a $csv $table
	    fi
	    echo "Generated $table"

	    # Combine all the html pieces
	    if [ $excel == $input ]; then
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

	    echo "Generated $index"
	else
	    echo "$input is not a proper XLS/XLSX file"
	    exit 1
	fi
    done
    cat archive/archive.index.bottom >> $arcindex

    echo
    echo "Site ready!"
fi
