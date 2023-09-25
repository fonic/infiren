## Changelog for v4.0 release

Changes:

- Added support for user-editable configuration file (i.e. `infiren.conf`)
- Added feature to load/save command history from/to file on startup/exit
- Added feature to save/load macros to/from file (commands `save-macro`/`load-macro`)
- Extended `undo` command to allow undoing/redoing entire macros
- Reworked several commands to accomodate new commands (e.g. `start-macro` + `end-macro` -> `record-macro`)
- Applied various minor code modification (variables, comments, errors, etc.)

## Changelog for v3.11 release

Initial release (versions prior to v3.11 have not been published).

Features:
- Various editing commands (including regular expressions)
- File filtering (pattern, invert, case sensitive/insensitive)
- Recursive mode (to include files of subfolders)
- Macro recording and replay (to reuse a set of commands)
- Undo/redo of last name-altering operation
- Actual renaming only occurs when when issuing `apply`/`save`

##

_Last updated: 09/25/23_
