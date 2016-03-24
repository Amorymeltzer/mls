#!/usr/bin/env bash
# generate_data.sh by Amory Meltzer
# Create the proper index page, including sorting

#### Rewrite plans
## Run multipleWorksheets.pl
## Generate season index (chart, table)
## Generate individual gameday index (table)
## Move tournament results to appropriate place
## Generate tournament index (csv, table)
## Generate index, archive page (ordered) with tournaments
## Games link back to main season; season links to all individual games+tournys

function get_help {
    cat <<END_HELP

Usage: $(basename $0) -i <current_season.xlsx> [-ulh]

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
    #arcindex="archive/index.html"
    #cat archive/archive.index.top > $arcindex

    # Grab everything...
    #  FILES=$(find -E . -regex "./.*mls_.*xlsx?" | grep -v _site)
    #  FILES=$(find -E . -regex "./.*[sfu][0-9][0-9].*csv" | grep -v _site)
    FILES=$(find -E . -maxdepth 1 -regex "./.*_[sfu][0-9][0-9].*csv" | grep -v _site)
    echo $FILES

    # # Sort files chronologically
    # FILES=$(perl sortFiles.pl $FILES)
    # echo $FILES

    # Die if no proper files can be found
    if [ -z "$FILES" ]; then
	echo "No valid files given!!!"
	exit
    fi

    for csv in $FILES
    do
	# find insists on a leading ./ - I generally won't be providing such
	# things when running this but it's a good thing to watch out for when
	# sanitizing
	csv=$(echo $csv | perl -pe 's/^.\///;')
	# Prune file format
	file=$(echo $csv | perl -pe 's/\.csv$//;')
	# Build table
	# Only handles seasons at the moment FIXME TODO
	table=''
	if [ $(echo $csv | grep -oE "mls_[sfu][0-9][0-9].csv") ]; then
	    table=$(echo $file.table)
	    perl makeMLSTable.pl $csv $table
	fi

	# Generate names of subfolders
	season=$(echo $csv | grep -oE "[sfu][0-9][0-9]")
	game=$(echo $csv | grep -oE "[0-9][0-9]\.[0-9][0-9]")

	# Check each folder individually, avoid overwriting any data
	if [ -n $game ]; then	# Individual game data
	    if [ ! -d $season/$game ]; then
		mkdir -p $season/$game/
	    fi
	    mv $csv $table $season/$game
	elif [ -n $season ]; then # Season-total
	    if [ ! -d $season ]; then
		mkdir -p $season/
	    fi
	    mv $csv $table $season
	else
	    echo "Warning: unable to properly file $csv"
	fi
    done

    # Properly indent file
    #emacs -batch $arcindex --eval '(indent-region (point-min) (point-max) nil)' -f save-buffer 2>/dev/null

    echo
    echo "Site ready!"
fi





exit





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
	# find insists on a leading ./ - I generally won't be providing such
	# things when running this but it's a good thing to watch out for when
	# sanitizing
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
		news=news.html
		bottom=bottom.html
	    else
		index=$file.html
		top=archive_top.html
		news=/dev/null
		bottom=archive_bottom.html
		perl makeArchiveIndex.pl $file $arcindex
	    fi

	    cat $top > $index
	    cat $news >> $index
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
    # Properly indent file
    emacs -batch $arcindex --eval '(indent-region (point-min) (point-max) nil)' -f save-buffer 2>/dev/null

    echo
    echo "Site ready!"
fi
