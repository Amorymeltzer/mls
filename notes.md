- htmlproof stuff
- https://github.com/gjtorikian/html-proofer
### ToDo
- Convert to python?
- Individual column sorting? https://github.com/tristen/tablesort/pull/97
- Reorganize files (data, js, etc. folders)
- Change summer u to m?  For sorting (ie everything before t)
- Propagate use English esp $PROGRAM_NAME for $0
### Future design
- Front with brief splash, link to current/ongoing past stats
- 1 or 2 photos, link photos page?
- Move all stats to /stats, archive to /stats/archive
- Convert data to individual game stats, so can do game-by-game progression
- More content! :+1: :100: :+1:
### Stats
- Team stats (RF/RA), record, etc.?
- More sabermetrics?  wOBA, others?
- Stat predictions, goals?  PCA plots? -> Joe
- Per-game data, graph if played more than one game (cut down on 1-off anomalies) (20% threshold?)
#### Archive system
- List individual pages on main page index.html (sorted by date?)
- Small links to other archived tables - next/previous seasons?
- One line, not multiple lines
- Tournament index
- Tournaments link back to tourny index and home

### Revamp plan
- Stats for individual games, one per worksheet (google doc, name: Season Year MM/DD))
- Keep data sum for each individual season, show graph for each season?
- Splash page welcomes, has TOC with: current season table and graphs, archives, photos
- Individual stats with goal AVG?  Would need a player page...
- Insert TB or not?
- Set axis for calculated stats to start at 0?  Should start at zero for everyone?
- PA/AB/etc. checks for division by zero, proper sums (H+K+BB+SAC<PA, etc.)

### HTML rewrite
- Get it right
- Why so small?  Font size shrunk but the table is tiny
- Maybe beef up font size?  Or just table size?
- Figure out how to generate season index of individual games
- That could tie in well with news header and "archive" footer?
- Use makeArchiveIndex.pl like sortFiles.pl to produce before moving other files
