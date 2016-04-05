### ToDo
- Convert to python, R?
- Individual column sorting? https://github.com/tristen/tablesort/pull/97
- More content! :+1: :100: :+1:
#### Stats
- Team stats (RF/RA), record, etc.?
- More sabermetrics?  wOBA, others?
- Stat predictions, goals?  PCA plots? -> Joe
- Individual stats with goal AVG?  Would need player pages...
- Sort players by batting order?  Eh.
#### Archive system
- Small links to other archived tables - next/previous seasons?
- Should mainpage list seasons from oldest to newest, newest to oldest, or old to new within a year, or what?  Maybe new line for each year?
#### Revamp plan
- PA/AB/etc. checks for division by zero, proper sums (H+K+BB+SAC<PA, etc.)
- Link to schedule on main page?
- Check out D3plus? https://github.com/alexandersimoes/d3plus/ and http://d3plus.org/examples/advanced/9862486/
#### JS
- Why does the header h3 for the table appear above the chart, below chart h3 header, on season index?
- Fix mouseover tooltip on final newly-created points
- If someone misses the first game, each calculated stat will start at 0; this will lead to a lot of annoying, 0-based graphs clumping in the middle
- Need to figure out how to get the line.defined and data.filter functions to work properly with NaN/null/0
- Alternatively, just change the y.domain to minimum non-0 value.
- Labels overlap, can I deal with that?  Force-directed?
- Or use a legend?  http://d3-legend.susielu.com or http://www.competa.com/blog/2015/07/d3-js-part-7-of-9-adding-a-legend-to-explain-the-data/
