- htmlproof stuff
- https://github.com/gjtorikian/html-proofer
### ToDo
- index.html should display total or season or...?  Get input
- Use perl to parse csv, skip xlscat entirely?
- Convert to python?
- Parse main, joint xlsx into csv (skip intermediate xlsx, (tables?))
- Be better about picking seasons (multipleWorksheets.pl)
- Individual column sorting? https://github.com/tristen/tablesort/pull/97
- Reorganize files (data, js, etc. folders)
- Change summer u to m?  For sorting (ie everything before t)
- Remove AB, just use PA (math, templates, game data, etc.)
### Future design
- Front with brief splash, link to current/ongoing past stats
- 1 or 2 photos, link photos page?
- Move all stats to /stats, archive to /stats/archive
- Convert data to individual game stats, so can do game-by-game progression
- More content! :+1: :100: :+1:
### Stats
- Team stats (RF/RA), record, etc.
- More sabermetrics?  wOBA, others?
- Individual stats/graphs over time? -> Joe
- Per-game data, graph if played 1 or more games (cut down on 1-off anomalies) (15-20% threshold)
- plotly for graphs, etc?  python or r?
- See also http://mikecostelloe.com/crazyrhythms/ and https://github.com/MikeCostelloe/crazy-rhythms
- js/standings.js
#### Archive system
- List individual pages on main page index.html (sorted by date?)
- Small links to other archived tables - next/previous seasons?

### Revamp plan
- Stats for individual games, one per worksheet (google doc, name: Season Year MM/DD))
- Parse into csv for each stat measured (multipleWorksheets.pl)
- Also parse into per-season data  (multipleWorksheets.pl)
- Columns with game id (stretch over seasons), date, and individuals
- Keep data sum for each individual season, show graph for each season?
- What do with generate_data?  Need to figure out workflow, python parsing/graphing scripts
- Splash page welcomes, has TOC with: current season table and graphs, archives, photos
- Manually calculate (ie not in excel/google sheets) stats?
