
## Changelog for v4.2 release (04/25/24)

**Changes:**
- Added multi-platform support (_FreeBSD_, _macOS_ and _Windows_)
- Improved error detection and handling
- Updated `README.md` to include information for newly supported platforms
- Reformatted `README.md` and `CHANGELOG.md` to improve readability when using
  plain text viewers/editors (i.e. without Markdown rendering)
- Cleaned up and refactored code, applied various minor changes (functions,
  comments, variables, prints, etc.)


## Changelog for v4.1-dev release (04/13/24)

Intermediate development release (has not been published).

**Changes:**
- Separated macro handling code/state into macro and command playback
- Added support for using CTRL+D to abort currently running command playback
- Added feature to optionally specify commands to be executed right after
  startup via command line
- Performed code cleanup and refactoring for all functions (underscore
  variables, return values)
- Applied various minor code modification (variables, comments, errors, etc.)


## Changelog for v4.0 release (09/25/23)

**Changes:**
- Added support for user-editable configuration file (i.e. `infiren.conf`)
- Added feature to load/save command history from/to file on startup/exit
- Added feature to save/load macros to/from file (commands `save-macro`/
  `load-macro`)
- Extended `undo` command to allow undoing/redoing entire macros
- Reworked several commands to accommodate new commands (e.g. `start-macro` +
  `end-macro` -> `record-macro`)
- Applied various minor code modification (variables, comments, errors, etc.)


## Changelog for v3.11 release (09/13/23)

Initial release (versions prior to v3.11 have not been published).

**Features:**
- Various editing commands (including regular expressions)
- File filtering (pattern, invert, case sensitive/insensitive)
- Recursive mode (to include files of subfolders)
- Macro recording and replay (to reuse a set of commands)
- Undo/redo of last name-altering operation
- Actual renaming only occurs when when issuing `apply`/`save`


##

_Last updated: 04/25/24_
