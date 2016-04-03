### ToDo
- Convert to python?
- Individual column sorting? https://github.com/tristen/tablesort/pull/97
- More content! :+1: :100: :+1:
#### Stats
- Calculate normalized stats?  3HR in 2 games versus 4HR in 5 games?  Not sure how this would work...
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
#### JS
- Why does the header h3 for the table appear above the chart, below chart h3 header, on season index?  Jekyll issue?
- Fix mouseover tooltip on final newly-created points
- Show game dates on game pages?  makeMLSTable.pl to show game date in table header
- Also show underneath, instead of GORDON! ??  Or just game date??
- If someone misses the first game, each calculated stat will start at 0; this will lead to a lot of annoying, 0-based graphs clumping in the middle
- Need to figure out how to get the line.defined and data.filter functions to work properly with NaN/null/0
#### HTML rewrite
- Update news for start of season!
- Why so small?  Font size shrunk but the table is tiny
- Maybe beef up font size?  Or just table size?
- Might be jekyll artifact, check when live
