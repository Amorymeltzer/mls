#!/usr/bin/env bash
# build_site.sh by Amory Meltzer
# Parse data, build index, piece together html


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


# Coming from perl, bash's flexibility with variables makes me uncomfortable
function print() {
    cat $top > $index
    cat $news >> $index
    cat $chart >> $index
    cat $table >> $index
    cat $arc >> $index
    cat $bottom >> $index
    cat templates/site_footer >> $index

    emacs -batch $index --eval '(indent-region (point-min) (point-max) nil)' -f save-buffer 2>/dev/null

    echo "Generated $index"
}


if [ ! "$input" ]; then
    echo "Please specify an XLS/XLSX data file"
    exit 1
else
    # Should probably test to ensure the file is valid first... FIXME TODO

    # Main process: parses master excel and produces/calculates all data
    perl multipleWorksheets.pl $input

    # Get all the games and seasons and tournaments that need linking to
    SUBS=$(find -E . -regex "./mls_.*_.*.csv" -o -regex "./mls_t....csv" | grep -v _site)
    # Generate archive index lists via
    perl makeArchiveIndex.pl $SUBS

    # Grab everything...
    FILES=$(find -E . -maxdepth 1 -regex "./.*_t?[sfu][0-9][0-9].*csv" | grep -v _site)
    FILES="$FILES ./masterData.csv" # Add lifetime totals

    # Die if no proper files can be found
    if [ -z "$FILES" ]; then
	echo "No valid files given!!!"
	exit
    fi

    for csv in $FILES
    do
	# find insists on a leading ./ - I won't be providing such things when
	# running this but it's a good thing to watch out for when sanitizing
	csv=$(echo $csv | perl -pe 's/^.\///;')
	# Prune file format
	file=$(echo $csv | perl -pe 's/\.csv$//;')

	# Generate names of subfolders
	season=$(echo $file | grep -oE "t?[sfu][0-9][0-9]")
	game=$(echo $file | grep -oE "[0-9][0-9]\.[0-9][0-9]")

	# Set default values ahead of time
	index=index.html
	news=/dev/null
	chart=templates/chart
	arc=/dev/null

	# Build tables
	table=$(echo $file.table)
	# Tournaments are halfway between seasons and games
	# Should be able to make this more efficient FIXME TODO
	if [ $(echo $season | grep -oE "t[sfu][0-9][0-9]") ]; then
	    perl makeMLSTable.pl -ag $csv $table # Game index
	    chart=/dev/null
	elif [ $(echo $file | grep -oE "mls_[sfu][0-9][0-9]") ]; then
	    if [ $(echo $file | grep -oE "mls_[sfu][0-9][0-9]_") ]; then
		perl makeMLSTable.pl -ag $csv $table # Game index
	    else
		perl makeMLSTable.pl -a $csv $table # Season index
		# Set here to avoid tourny errors FIXME TODO
		arc=templates/$season.list
	    fi
	elif [ $(echo $csv | grep -oE "masterData.csv") ]; then
	    perl makeMLSTable.pl $csv $table
	fi

	# Check each folder individually, avoid overwriting any data
	if [[ -n $game ]]; then	# Individual game data
	    if [[ ! -d $season/$game ]]; then
		mkdir -p $season/$game/
	    fi
	    index=$season/$game/$index
	    chart=/dev/null
	    top=templates/game.index.top
	    arc=/dev/null
	    bottom=templates/game.index.bottom
	    print

	    mv $csv $table $season/$game
	elif [[ -n $season ]]; then # Season-total
	    if [[ ! -d $season ]]; then
		mkdir -p $season/
	    fi
	    # Only generate if season total
	    if [ $(echo $file | grep -oE "mls_t?[sfu][0-9][0-9]") ]; then
		index=$season/$index
		top=templates/season.index.top
		bottom=templates/season.index.bottom
		print
	    elif [ ! $(echo $file | grep -oE "mls_t?[sfu][0-9][0-9]") ]; then
		# Rename and be done with season-based stats
		# Stash in data directory
		#mv $csv $season/$(echo $csv | sed -E 's/_[sfu][0-9][0-9]//')
		if [[ ! -d $season/data/ ]]; then
		    mkdir -p $season/data/
		fi

		mv $csv $season/data/$(echo $csv | sed -E 's/_[sfu][0-9][0-9]//')
		continue
	    fi

	    mv $csv $table $season
	elif [ $(echo $csv | grep -oE "masterData.csv") ]; then
	    top=templates/top
	    news=templates/news
	    arc=templates/arc.list
	    bottom=templates/bottom
	    print
	else
	    echo "Warning: unable to properly file $csv"
	fi
    done

    # Move lifetime stats as well
    FILES=$(find -E . -maxdepth 1 -regex "./.{1,3}\.csv" | grep -v _site)
    if [[ ! -d data/ ]]; then
	mkdir -p data/
    fi
    for csv in $FILES
    do
	mv $csv data/$csv
    done

    echo
    echo "Site ready!"
fi
