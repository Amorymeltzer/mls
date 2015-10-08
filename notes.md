### ToDo
- Better commenting!
- Sanitize files
- Build checks to ensure data and site build are valid
- Check if input handled properly, not in files, etc
- index.html should display total or season or...?  Get input
- Photo section?
#### Archive system
- List individual pages on main page index.html (sorted by date?)
- Small links to other archived tables - next/previous seasons?
#### Multiple sheets
- Use multipleWorksheets.pl to deal with multiple sheets in xlscat
- xlscat -c mls.xlsx -S "Fall Tournament" 1>/dev/null 2>&1
- Make hash of 1-based worksheet number=>label/name
- Parse each worksheet (for loop)
- Print via Excel::Writer::XLSX
- Report
- Comments
#### Appearance
- Check iPad sizes
