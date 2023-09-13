# Interactive File Renamer (InFiRen)
Interactively rename multiple files from the command line. Especially useful to organize large collections (images, videos, music, etc.).

## Donations
I'm striving to become a full-time developer of [Free and open-source software (FOSS)](https://en.wikipedia.org/wiki/Free_and_open-source_software). Donations help me achieve that goal and are highly appreciated.

<a href="https://www.buymeacoffee.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/buymeacoffee-button.png" alt="Buy Me A Coffee" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://paypal.me/fonicmaxxim"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/paypal-button.png" alt="Donate via PayPal" height="35"></a>&nbsp;&nbsp;&nbsp;<a href="https://ko-fi.com/fonic"><img src="https://raw.githubusercontent.com/fonic/donate-buttons/main/kofi-button.png" alt="Donate via Ko-fi" height="35"></a>

## Download & Installation
Refer to the [releases](https://github.com/fonic/infiren/releases) section for downloads links. There is no installation required. Simply extract the downloaded archive to a folder of your choice.

## Usage
To run _infiren_, use the following commands (requires _Bash >= v4.0_):
```
$ cd infiren-vX.Y
$ ./infiren.sh [START-FOLDER]
```

Within _infiren_, use `help` to list available editing commands:
```
Available commands:
rs, replace-string <str> <rep>   Replace string <str> with replacement <rep>
re, replace-regex <re> <tmp>     Match regular expression <re> and replace
                                 matching string according to template <tmp>
                                 Example: re "([0-9]+)x([0-9]+)" "S\1E\2"
pr, pre, prepend <str>           Prepend string <str>
ap, post, append <str>           Append string <str>
rd, replace-dots                 Replace single dots with spaces
id, insert-dash                  Insert dash after first word
ca, capitalize                   Capitalize space-separated words
up, upper, uppercase             Convert all characters to uppercase
lo, lower, lowercase             Convert all characters to lowercase
tr, trim, st, strip              Trim leading & trailing whitespace

sm, start-macro                  Start recording macro
em, end-macro                    Stop recording macro
vm, view-macro                   View macro contents
cm, clear-macro                  Clear macro contents
rm, replay-macro                 Replay commands from macro

hm, history-macro                Create macro from command history
vh, view-history                 View command history
ch, clear-history                Clear command history

sf, set-filter <pattern>         Set filter to <pattern> and reload
if, invert-filter                Invert filter and reload
cf, case-filter                  Toggle filter case and reload
vf, view-filter                  View current filter state
rf, reset-filter                 Reset filter and reload

ed, edit <index>                 Manually edit entry with index <index>
ud, undo                         Undo last name-altering operation
rc, recursive                    Toggle recursive mode and reload
cd, chdir <path>                 Change to directory <path> and reload

apply, save                      Apply changes (i.e. rename files)
reset, reload                    Discard changes and reload file names

help, usage                      Display this help/usage text
exit, quit                       Exit program (shortcut: CTRL+D)
```

## Showcase

![Animated GIF](https://raw.githubusercontent.com/fonic/infiren/master/SHOWCASE.gif)


##

_Last updated: 09/13/23_
