function pagesubnamer() {
    // Lookup hash for month name
    var h = {};
    h['04'] = 'April';
    h['05'] = 'May';
    h['06'] = 'June';
    h['07'] = 'July';
    h['08'] = 'August';
    h['09'] = 'September';
    h['10'] = 'October';


    var url = location.pathname.split('/');
    url.pop();			// Remove trailing null
    var last = url.pop().split('');
    // Get month number for lookup hash
    var month = last.shift();
    month += last.shift();
    name = h[month];
    name += ' ';
    // Get game date, no padding
    last.shift();		// Remove pesky .
    if (last[0] == '0') {
	last.shift();
    } else {
	name += last.shift();
    }
    name += last.shift();

    document.write(name);
};
pagesubnamer();
