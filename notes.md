- htmlproof stuff
- https://github.com/gjtorikian/html-proofer
### ToDo
- index.html should display total or season or...?  Get input
- Convert to python?
- Be better about picking seasons (multipleWorksheets.pl)
- Individual column sorting? https://github.com/tristen/tablesort/pull/97
- Reorganize files (data, js, etc. folders)
- Change summer u to m?  For sorting (ie everything before t)
### Future design
- Front with brief splash, link to current/ongoing past stats
- 1 or 2 photos, link photos page?
- Move all stats to /stats, archive to /stats/archive
- Convert data to individual game stats, so can do game-by-game progression
- More content! :+1: :100: :+1:
### Stats
- Team stats (RF/RA), record, etc.?
- More sabermetrics?  wOBA, others?
- Individual stats/graphs over time? -> Joe
- Stat predictions, goals?  PCA plots? -> Joe
- Per-game data, graph if played more than one game (cut down on 1-off anomalies) (20% threshold?)
- plotly for graphs, etc?  python or r?
- See also http://mikecostelloe.com/crazyrhythms/ and https://github.com/MikeCostelloe/crazy-rhythms
- js/standings.js
#### Archive system
- List individual pages on main page index.html (sorted by date?)
- Small links to other archived tables - next/previous seasons?

### Revamp plan
- Stats for individual games, one per worksheet (google doc, name: Season Year MM/DD))
- Keep data sum for each individual season, show graph for each season?
- What do with generate_data?  Need to figure out workflow, python parsing/graphing scripts
- Splash page welcomes, has TOC with: current season table and graphs, archives, photos
- Individual stats with goal AVG?  Would need a player page...
- Average batting order for ranking?  Prob not worth it.
- Insert TB or not?
- Set axis for calculated stats to start at 0?  Should start at zero for everyone?
- Adjust formatting in index3, margins, width, styles, etc.
- Sortable table below?  Don't use div for graph?
- PA/AB/etc. checks for division by zero, proper sums (H+K+BB+SAC<PA, etc.)
