### ToDo
- Player noisiness is a real issue if they missed the first X games.  Currently not figuring for it but should
- Not a huge issue given running data stuff atm, but it's there
- Should probably reconcile cumulative stats starting at 0 for people midway but NaN for calculated
- Really just clean up build_site.sh and multipleWorksheets.pl!
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
- Recalibrate threshold - maybe move toward specific values (5 for lifetime, 3 for running, 2 for season?)
- Figure out how much I can (mostly) stop skipping data and just let the noise in on the lifetime and season pages
- Could create player page alongside data, but might need to swap masterDates and dudes order in masterData parsing
- Link game dates in graph or table or something to individual pages?
#### Stats
- More content! :+1: :100: :+1:
- Could we maybe do an ELO score?  Curious how this would look year to year, maybe manually grab data from facebook?
- Would probably need to be a separate workflow
- Team stats (RF/RA), PCA plots?
- Calcuate oWAR from full team averages?  Need to reform wOBA first and look toward RAA
- How do I calculate wOBA scale?  Scaled to OBP but what does that mean?
- Could show team average, at least for calculated stats
- Individual stats with predictions, goal AVG?  Would need player pages...
- Can I pull this info from masterData?  Maybe.
- Show lifetime graph and list per-season stat lines?
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
