### ToDo
- Player noisiness is a real issue if they missed the first X games.  Currently not figuring for it but should
- Should probably reconcile cumulative stats starting at 0 for people midway but NaN for calculated
#### Migrate to D3 v4
- Ticks might be easier to manipulate https://github.com/d3/d3-array/blob/master/README.md#ticks
- Selections https://github.com/d3/d3/blob/master/CHANGES.md#selections-d3-selection
- Transitions https://github.com/d3/d3/blob/master/CHANGES.md#transitions-d3-transition
- d3.active allows chained transitions for example
- Colors are different, and now have opacity (who cares?) and perhaps new color scales
#### Revamp plan
- Deal with double-headers.  Easy to just advance day by one but ugly.  Prettier than the code needed for a workaround though...
- Convert to python, R?
- Change as many elements as possible from px to (r)em
- Link to schedule on main page?  Or show upcoming/next game(s)?
- Videos?  gh-pages can't embed, but maybe plyr.js can?
- Zoom, reset https://github.com/d3/d3-zoom
- http://bl.ocks.org/mbostock/3892928 and http://bl.ocks.org/mbostock/4dc8736fb1ce9799c6d6
##### Front page rewrite
- Make front page stats for last 10 or 15 games, move lifetime to subpage a la seasons?
- This this would also allow me to (maybe?) stop skipping data, and just let the noise in on the full picture and season pages
- Could do this by making a running hash from the last 17 or so dates, then crunch first few for noise and 15 total
- Would need to derive player names, I think, but maybe I can lean on the availability and veracity of the data, which by this time should be established
- This this would also allow me to stop skipping data, and just let the noise in on the full picture and season pages
- Link game dates in graph or table or something to individual pages?
- Better(?) way might be to do a running hash of hash, with player names as lookups for a binary 1 or 0 on each date?  Awkward, but I could rederive the data this way
- Rely on the overall number of sheets to get total number of dates, thus allowing me to anticipate when data collection needs starting?
- Need to deal with page creation, templates, and the creation of the lifetime directory
#### Stats
- More content! :+1: :100: :+1:
- Team stats (RF/RA), PCA plots?
- Calcuate oWAR from full team averages?  Need to reform wOBA first and look toward RAA
- How do I calculate wOBA scale?  Scaled to OBP but what does that mean?
- Could show team average, at least for calculated stats
- Individual stats with predictions, goal AVG?  Would need player pages...
- Player page could show graph with total/cumulative stats, list results per season
- Or good place to show some sort of scatter graph?  I'm sure some saber site has a good example
- Or perhaps one of those radial diagrams?  With various stats?  Relates to PCA...
#### JS
- Skip some x-axis labels to save space.  Should probably extend margin a bit...
- Check out D3plus? https://github.com/alexandersimoes/d3plus/ and http://d3plus.org/examples/advanced/9862486/
- Or Chartjs? https://github.com/chartjs/Chart.js
- Labels overlap, how can I deal with that?  Force-directed?
- Or use a legend?  http://d3-legend.susielu.com or http://www.competa.com/blog/2015/07/d3-js-part-7-of-9-adding-a-legend-to-explain-the-data/
- Check out pre-rendering: https://github.com/fivethirtyeight/d3-pre
- Requires some npm stuff first...
