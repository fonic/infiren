
# Interactive File Renamer (InFiRen)

Interactively rename multiple files from the command line. Especially useful to
organize large collections of images, videos, music, etc.


## Donations

I'm striving to become a full-time developer of [Free and open-source software
(FOSS)](https://en.wikipedia.org/wiki/Free_and_open-source_software). Donations
help me achieve that goal and are highly appreciated.

<a href="https://www.buymeacoffee.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/buymeacoffee-button.png" alt="Buy Me A Coffee" height="35"></a>&nbsp;&nbsp;
<a href="https://paypal.me/fonicmaxxim"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/paypal-button.png" alt="Donate via PayPal" height="35"></a>&nbsp;&nbsp;
<a href="https://ko-fi.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/kofi-button.png" alt="Donate via Ko-fi" height="35"></a>


## Requirements

**Operating System:**<br/>
_Linux_, _FreeBSD_, _macOS_, _Windows_

**Dependencies:**<br/>
_Bash_ (>=v5.0), _GNU find_ (part of [findutils](https://www.gnu.org/software/findutils/))
-or- _BSD find_ (available on FreeBSD/macOS), _coreutils_ (provide basic tools
like `dirname`, `basename`, `mkdir`, `sort`, etc.)

**Note:**<br/>

_macOS_ users might want to use [Homebrew](https://brew.sh/) to install
missing dependencies.

_Windows_ users need to set up a suitable runtime environment:
[Cygwin](https://www.cygwin.com/),
[MSYS2](https://www.msys2.org/),
[Git for Windows](https://git-scm.com/download/win) or
[Windows Subsystem for Linux](https://learn.microsoft.com/en-us/windows/wsl/about)
should all work fine.
[Git for Windows](https://git-scm.com/download/win)
might be a good choice to get started - it is reasonably lightweight, easy to
to set up, meets all requirements out of the box and is also available as a
portable version.


## Download & Installation

Refer to the [releases](https://github.com/fonic/infiren/releases) section for
downloads links. There is no actual installation required. Simply extract the
downloaded archive to a folder of your choice.


## Configuration

Open `infiren.conf` in your favorite text editor and adjust the settings to
your liking. Refer to embedded comments for details. Refer to
[this section](#configuration-options) for a list of configuration options and
current defaults.


## Quick Start

To start _InFiRen_, use the following command (specifying an initial directory
is optional):
```
$ infiren.sh [INITIAL-DIRECTORY]
```

Within _InFiRen_, enter `help` or refer to [this section](#interactive-commands)
for a list of available _interactive commands_.

Run `infiren.sh --help` or refer to [this section](#command-line-options) for
a list of available _command line options_.


## Showcase

<a href="https://raw.githubusercontent.com/fonic/infiren/master/SHOWCASE.gif">
<img src="https://raw.githubusercontent.com/fonic/infiren/master/SHOWCASE.gif" title="Click to enlarge" alt="Animated GIF" width="960" height="680">
</a>


## Interactive Commands

Available interactive commands:
```
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
pm, play-macro                Play back commands stored in macro
pd, playback-delay VALUE      Set delay in between commands for command
                              playback to VALUE (in seconds, fractions
                              are supported)

sm, save-macro NAME           Save macro using name NAME to macro file
lm, load-macro NAME           Load macro named NAME from macro file
dm, delete-macro NAME         Delete macro named NAME from macro file
im, list-macros               List all macros stored in macro file

hm, history-macro             Create macro from command history
vh, view-history              View command history
ch, clear-history             Clear command history

fp, filter-pattern PATTERN    Set filter pattern to PATTERN and reload
                              files
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


## Command Line Options

Available command line options:
```
Usage: infiren.sh [INITIAL-DIRECTORY] [CMD]...
Note:  Commands are executed right after startup
```


## Configuration Options

Available configuration options (and defaults):
```sh
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

# Initial command playback delay (in seconds, fractions are supported; '0' ==
# no delay)
PLAYBACK_DELAY="0.25"

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

_Last updated: 04/25/24_
