function pagenamer() {
    var title = '';		// Build upon later
    var h = {};			// Lookup hash
    h['s'] = 'Spring';
    h['u'] = 'Summer';
    h['f'] = 'Fall';
    h['l'] = 'Lifetime';

    var url = location.pathname.split('/');
    url.shift();		// Remove leading null
    url.shift();		// Remove leading mls
    var season = url.shift().split('');
    if (season[0] == 't') {
	season.shift();
	title = 'Tournament ';
    }

    // Lookup season
    var seas = season.shift();
    title += h[seas];
    // Lifetime stats are special
    if (season[0] == 'i') {
	title += 'Stats';
    } else {
	// Year
	title += ' 20';
	title += season.shift();
	title += season.shift();
    }
    document.write(title);
};
pagenamer();
