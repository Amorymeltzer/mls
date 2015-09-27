### ToDo
- Sanitize files
- Inputs MUST be named mls_[suf]\d\d.xlsx?
- What about tournament data?
- Build checks to ensure data and site build are valid
- Better commenting!
- Nothing after total, nothing past OPS
- Homepage link - gordon, image, on top of archive
- Potentially deal with multiple sheets in xlscat
- xlscat -c mls.xlsx -S "Fall Tournament" 1>/dev/null 2>&1
- index.html should display total or season or...?
- Get input from Joe, team
#### Archive system
- Sorting
- Appearance
- Total versus current versus past
#### Planning
##### bash
- Check if input handled properly, not in files, etc
##### perl
- List individual pages on main index.html (sorted by date?)
- Sort index page by season (separate perl to parse input to generate??)
- Small links to other archived tables - next/previous seasons or just archive index?
#### Appearance
- Check iPad sizes
- Better gradient?
- Use stylesheet/span for archive backlinks (arbcom-style) resizing
