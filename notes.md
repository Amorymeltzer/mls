- htmlproof stuff
- https://github.com/gjtorikian/html-proofer
### ToDo
- index.html should display total or season or...?  Get input
- Use perl to parse csv, skip xlscat entirely?
- Convert to python?
- Parse main, joint xlsx into csv (skip intermediate xlsx, (tables?))
- Be better about picking seasons (multipleWorksheets.pl)
- Individual column sorting? https://github.com/tristen/tablesort/pull/97
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
- Per-game data, graph if played 1 or more games (cut down on 1-off anomalies)
- plotly for graphs, etc?  python or r?
- See also http://mikecostelloe.com/crazyrhythms/ and https://github.com/MikeCostelloe/crazy-rhythms
#### Archive system
- List individual pages on main page index.html (sorted by date?)
- Small links to other archived tables - next/previous seasons?

### Revamp plan
- Stats for individual games, one per worksheet (google doc, name: Season Year mm/dd/yy)
- Parse into csv for each stat measured (multipleWorksheets.pl)
- Also parse into per-season data  (multipleWorksheets.pl)
- Columns with game id (stretch over seasons), date, and individuals
- Keep data sum for each individual season, show graph for each season?
