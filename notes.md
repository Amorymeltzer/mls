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
- Confirmatory output sorted by time not season?  Everything works but it's unnerving
##### Front page rewrite
- Make front page stats for last 10 or 15 games, move lifetime to subpage a la seasons?
- Could do this by making a running hash from the last 17 or so dates, then crunch first few for noise and 15 total
- Would need to derive player names, I think, but maybe I can lean on the availability and veracity of the data, which by this time should be established
- This this would also allow me to stop skipping data, and just let the noise in on the full picture and season pages
#### Stats
- More content! :+1: :100: :+1:
- Team stats (RF/RA), PCA plots?
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
