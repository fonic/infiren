# Interactive File Renamer (InFiRen)
Interactively rename multiple files from the command line. Especially useful to organize large collections (images, videos, music, etc.).

## Donations
I'm striving to become a full-time developer of [Free and open-source software (FOSS)](https://en.wikipedia.org/wiki/Free_and_open-source_software). Donations help me achieve that goal and are highly appreciated.

<a href="https://www.buymeacoffee.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/buymeacoffee-button.png" alt="Buy Me A Coffee" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://paypal.me/fonicmaxxim"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/paypal-button.png" alt="Donate via PayPal" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://ko-fi.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/kofi-button.png" alt="Donate via Ko-fi" height="35"></a>

## Requirements
**Dependencies:**<br/>
_Bash (>=v4.0)_, _GNU find_ (part of [findutils](https://www.gnu.org/software/findutils/))

**Platforms:**<br/>
_Linux_ (NOTE: support for macOS/FreeBSD/Windows will be added in a future release)

## Download & Installation
Refer to the [releases](https://github.com/fonic/infiren/releases) section for downloads links. There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Configuration
Open `infiren.conf` in your favorite text editor and adjust the settings to your liking. Refer to embedded comments for details. Refer to [this section](#configuration-options--defaults) for a listing of all configuration options and current defaults.

## Usage
To start _infiren_, run the following commands:
```
$ cd infiren-v4.0
$ ./infiren.sh [INITIAL-DIRECTORY]
```

Within _infiren_, use `help` to list available commands:
```
Available commands:
rs, replace-string STR REP    Replace string STR with replacement REP
re, replace-regex RE TMP      Match regular expression RE and replace
                              matching string according to template TMP
                              (e.g. re "([0-9]+)x([0-9]+)" "S\1E\2")
pr, pre, prepend STR          Prepend string STR
po, post, append STR          Append string STR
rd, replace-dots              Replace single dots with spaces
id, insert-dash               Insert dash after first word
ca, capitalize                Capitalize space-separated words
up, upper, uppercase          Convert all characters to uppercase
lo, lower, lowercase          Convert all characters to lowercase
tr, trim, st, strip           Trim leading and trailing whitespace

rm, record-macro              Start/stop recording macro
vm, view-macro                View macro contents
cm, clear-macro               Clear macro contents
pm, play-macro                (Re-)Play commands from macro
md, macro-delay VALUE         Set delay in between commands for macro play-
                              back to VALUE (in seconds, supports fractions)

sm, save-macro NAME           Save macro using name NAME to macro file
lm, load-macro NAME           Load macro named NAME from macro file
dm, delete-macro NAME         Delete macro named NAME from macro file
im, list-macros               List all macros stored in macro file

hm, history-macro             Create macro from command history
vh, view-history              View command history
ch, clear-history             Clear command history

fp, filter-pattern PATTERN    Set filter pattern to PATTERN and reload files
if, invert-filter             Invert filter and reload files
fc, filter-case               Toggle filter case and reload files
vf, view-filter               View current filter state
rf, reset-filter              Reset filter and reload files

ed, edit INDEX                Manually edit entry with index INDEX
ud, undo                      Undo/redo last name-altering operation
rc, recursive                 Toggle recursive mode and reload files
cd, chdir PATH                Change directory to PATH and reload files

apply, save                   Apply changes (i.e. rename files)
reload, reset                 Discard changes and reload files

help, usage                   Display this help/usage text
exit, quit                    Exit program (shortcut: CTRL+D)
```

## Showcase

![Animated GIF](https://raw.githubusercontent.com/fonic/infiren/master/SHOWCASE.gif)

## Configuration Options & Defaults

Configuration options and current defaults:
```sh
# infiren.conf

# ------------------------------------------------------------------------------
#                                                                              -
#  Interactive File Renamer (InFiRen)                                          -
#                                                                              -
#  Created by Fonic <https://github.com/fonic>                                 -
#  Date: 04/23/19 - 09/25/23                                                   -
#                                                                              -
# ------------------------------------------------------------------------------

# Initial directory (if empty, current working directory is used)
INITIAL_DIRECTORY=""

# Initial filter pattern (see 'man find', option '-name pattern' for syntax;
# '*' == all files)
FILTER_PATTERN="*"

# Initial filter invert setting ('true'/'false'; 'true' == inversion enabled)
FILTER_INVERT="false"

# Initial filter case setting ('true'/'false'; 'true' == case sensitive)
FILTER_CASE="false"

# Initial recursive mode setting ('true'/'false'; 'true' == recursion enabled)
RECURSIVE_MODE="false"

# Initial macro playback delay (in seconds, fractions are supported; '0' == no
# delay)
MACRO_DELAY="0.25"

# Options passed to 'sort' when sorting file/folder listings (see 'man sort'
# for valid/available options)
SORT_OPTS=("-V")

# Load/save command history from/to file on startup/exit ('true'/'false')
PERSISTENT_HISTORY="true"

# File used to store command history (only if PERSISTENT_HISTORY is enabled)
# ${APP_DIR}:  directory where app executable ('infiren.sh') is stored
# ${APP_NAME}: name of app executable ('infiren.sh') without extension
# ${HOME}:     home directory of user running/executing the application
#HISTORY_FILE="${HOME}/.config/${APP_NAME}/${APP_NAME}.hst"
HISTORY_FILE="${APP_DIR}/${APP_NAME}.hst"

# File used to store macros (managed via commands 'save-macro'/'load-macro')
# ${APP_DIR}:  directory where app executable ('infiren.sh') is stored
# ${APP_NAME}: name of app executable ('infiren.sh') without extension
# ${HOME}:     home directory of user running/executing the application
#MACROS_FILE="${HOME}/.config/${APP_NAME}/${APP_NAME}.mac"
MACROS_FILE="${APP_DIR}/${APP_NAME}.mac"
```

##

_Last updated: 09/25/23_
