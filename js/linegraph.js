    <!--
// Heavily based on Mike Costelloe's Visual Rhythmes:
// http://mikecostelloe.com/crazyrhythms/
function linegraph() {
    // Customize, need to make these be relative not absolute pixel counts
    // FIXME TODO
    var margin = {top: 20, right: 120, bottom: 30, left: 80}
    , width = 0.85 * window.innerWidth
    , height = 0.7 * window.innerHeight
    , width = width - margin.left - margin.right
    , height = height - margin.top - margin.bottom;

    var svg = d3.select("#linegraph").append("svg")
	.attr("width", width + margin.left + margin.right)
	.attr("height", height + margin.top + margin.bottom)
	.append("g")
	.attr("transform", "translate(" + margin.left + "," + margin.top + ")");


    // Properly parse and nicely format dates
    var parseDate = d3.time.format("%m.%d.%y").parse;
    var formatDate = d3.time.format("%b %d, %Y");

    // Scales
    var x = d3.scale.ordinal()
	.rangePoints([0, width]);

    var y = d3.scale.linear()
	.range([height, 0]);

    // Colors
    // Should play with these FIXME TODO
    // See also below x2
    var color = d3.scale.category10();

    // Axes
    var xAxis = d3.svg.axis()
	.scale(x)
	.orient('bottom');

    var yAxis = d3.svg.axis()
	.scale(y)
	.orient('left');

    // Lines
    var line = d3.svg.line()
	.x(function(d) { return x(d.Date); })
	.y(function(d) { return y(d.Record); });


    // Data load and two console logs, before and after the data.map
    // Load data directly from directory
    d3.csv('data/R.csv', function(error, data) {

	// Splits into 10 colors by owner
	color.domain(d3.keys(data[0]).filter(function(key) { return key !== 'Date'; }));

	// Don't format opening values of zero
	data.forEach(function(d) {
	    if (d.Date !== 'Start') {
		d.Date = formatDate(parseDate(d.Date));
	    }
	});

	var owners = color.domain().map(function(name) {
	    return {
		name: name,
		values: data.map(function(d) {
		    return {Date: d.Date, Record: +d[name]};
		})
	    };
	});

	// x-Domain is date, evenly spaced
	x.domain(data.map(function(d) { return d.Date; }));

	// y-Domain is max of stat
	y.domain([
	    0,
	    d3.max(owners, function(c) { return d3.max(c.values, function(v) { return v.Record; }); })
	]);

	svg.append('g')
	    .attr('class', 'x axis')
	    .attr('transform', 'translate(0,' + height + ')')
	    .call(xAxis)
	    .append("text")
	    .attr("x", width)
	    .attr("y", -12)
	    .attr("dy", ".71em")
	    .style("text-anchor", "end")
	    .text("Date");

	svg.append('g')
	    .attr("class", "y axis")
	    .call(yAxis)
	    .append("text")
	    .attr("transform", "rotate(-90)")
	    .attr("y", 6)
	    .attr("dy", ".71em")
	    .style("text-anchor", "end")
	    .text("Weekly total");

	// Selects .owner class (none exist at first) and creates them as needed
	var owner = svg.selectAll('.owner')
	    .data(owners)
	    .enter().append('g')
	    .attr('class', 'owner');

	// Assigns each owner a line and a unique color for it
	owner.append('path')
	    .attr('class', 'line')
	    .attr('d', function(d) { return line(d.values); })
	    .style('stroke', function(d) { return color(d.name); })

	// Adds a circle to each data node
	owner.append('g').selectAll('circle')
	    .data(function(d) {return d.values; })
	    .enter().append('circle')
	    .attr('r', 5)
	    .attr('cx', function(c) { return x(c.Date); })
	    .attr('cy', function(c) { return y(c.Record); })
	    .attr('fill', function(d) { return color(this.parentNode.__data__.name); }) //pulls color from range in way I don't understand
	    .on('mouseover', function(d) {
		var xTip = parseFloat(d3.select(this).attr('cx'));
		var yTip = parseFloat(d3.select(this).attr('cy'));

		svg.append('text')
		    .attr('id', 'tooltip')
		    .attr('x', xTip + 5)
		    .attr('y', yTip - 10)
		    .attr('fill', 'black')
		    .text(d.Record);
	    })

	    .on('mouseout', function() {
		d3.select('#tooltip').remove()
	    });

	// Adds the names at the end
	owner.append("text")
	    .datum(function(d) { return {name: d.name, value: d.values[d.values.length - 1]}; })
	    .attr("transform", function(d) { return "translate(" + x(d.value.Date) + "," + y(d.value.Record) + ")"; })
	    .attr('class', 'labels')
	    .attr("x", 5)
	    .attr("dy", 5)
	    .attr('fill', function(d) { return color(this.parentNode.__data__.name); }) //pulls color from range in way I don't understand
	    .text(function(d) { return d.name; });

	// Dropdown menu listener
	d3.select("#menu").on("change", change);

	function change() {
	    var item = this.value;

	    d3.csv('data/' + item + '.csv', function(error, data) {

		// Don't format opening values of zero
		data.forEach(function(d) {
		    if (d.Date !== 'Start') {
			d.Date = formatDate(parseDate(d.Date));
		    }
		});

		var owners = color.domain().map(function(name) {
		    return {
			name: name,
			values: data.map(function(d) {
			    return {Date: d.Date, Record: +d[name]};
			})
		    };
		});

		// y-Domain to min/max of winPct's
		y.domain([
		    d3.min(owners, function(c) { return d3.min(c.values, function(v) { return v.Record; }); }),
		    d3.max(owners, function(c) { return d3.max(c.values, function(v) { return v.Record; }); })
		]);

		svg.select('.x.axis')
		    .call(xAxis);

		svg.select('.y.axis')
		    .call(yAxis);

		// Update class data
		svg.selectAll('.owner')
		    .data(owners);

		// Update lines
		owner.select('path')
		    .transition()
		    .attr('d', function(d) { return line(d.values); });

		// Update circles
		owner.selectAll('circle')
		    .data(function(d) { return d.values; })
		    .transition()
		    .attr('cy', function(c) { return y(c.Record); });

		// Update labels
		owner.select(".labels")
		    .datum(function(d) { return {name: d.name, value: d.values[d.values.length - 1]}; })
		    .transition()
		    .attr("transform", function(c) { return "translate(" + x(c.value.Date) + "," + y(c.value.Record) + ")"; })

	    })};
    });
};
linegraph();
