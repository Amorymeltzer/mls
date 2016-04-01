function pagenamer() {
    var title = '';		// Build upon later

    // Lookup hash
    var h = {};
    h['s'] = 'Spring';
    h['u'] = 'Summer';
    h['f'] = 'Fall';

    var season = location.pathname.split('');
    season.shift();		// Remove leading /
    if (season[0] == 't') {
	season.shift();
	title = 'Tournament ';
    }

    // Lookup season
    var seas = season.shift();
    title += h[seas];
    // Year
    title += ' 20';
    title += season.shift();
    title += season.shift();

    document.write(title);
};
pagenamer();
