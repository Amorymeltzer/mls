### ToDo
- Sanitize files
- Inputs MUST be named mls_[suf]\d\d.xlsx?
- Build checks to ensure data and site build are valid
- Nothing after total, nothing past OPS
#### Archive system
- Generation
- Index
- Pages

#### Planning
##### bash
- Get list of all xlsx
- Also allow xls via ls/find
- Recursively generate csv for each xlsx
- Use ** glob matching (would be bash4 dependent) for archive folder
- Do so in place ie archive folder
- Check if input handled properly, not in files, etc
- Rename table.html to just table or something
- Use mls_f14.html as index page - much neater
##### perl
- Everything except cl-provided file gets archived
- If 1, current text
- If >1, build archive page
- List individual pages on main index.html (sorted by date?)
- Main index page for entire index
- Each archive gets own, sortable table
- Links on subpages to go back to index a la enWiki ARBCOM <- AC/C/D/E
- Small links to other archived tables - next/previous seasons or just archive index?

- index.html should display total or season or...?
- Get input from Joe, team


#### Appearance
- Check iPad sizes
- Better gradient?
- Use stylesheet/span for archive sizing
