#!/usr/bin/env bash

# ------------------------------------------------------------------------------
#                                                                              -
#  Interactive File Renamer (InFiRen)                                          -
#                                                                              -
#  Created by Fonic <https://github.com/fonic>                                 -
#  Date: 04/23/19 - 04/25/24                                                   -
#                                                                              -
# ------------------------------------------------------------------------------


# --------------------------------------
#                                      -
#  Early birds                         -
#                                      -
# --------------------------------------

# Check if running Bash and required version (NOTE: this check does not rely on
# Bashism to make sure it is guaranteed to work on any POSIX shell)
if [ -z "${BASH_VERSION}" ] || [ "${BASH_VERSION%%.*}" -lt 5 ]; then
	echo -e "\e[1;31mError: this script requires Bash >= v5.0 to run, aborting.\e[0m"
	exit 1
fi

# Set up error handler (exit on unbound variables and on unhandled errors)
set -ueE; trap "echo -e \"\e[1;31mError: an unhandled error occurred on line \${LINENO}, aborting.\e[0m\"; exit 1" ERR


# --------------------------------------
#                                      -
#  Globals                             -
#                                      -
# --------------------------------------

# Application info (NOTE: realpath is not guaranteed to be available, e.g.
# macOS does not have it while FreeBSD does; stripping trailing '/' off of
# APP_DIR to account for root directory, i.e. '/'; could use ${APP_DIR%/}
# instead to build paths, but that would be needlessly confusing for users
# when being used within config file)
APP_TITLE="Interactive File Renamer (InFiRen)"
APP_VERSION="4.2 (04/25/24)"
if command -v realpath >/dev/null; then
	APP_DIR="$(dirname -- "$(realpath -- "$0")")"
	APP_FILE="$(basename -- "$(realpath -- "$0")")"
else
	APP_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
	APP_FILE="$(basename -- "$0")"
fi
APP_DIR="${APP_DIR%/}"
APP_NAME="${APP_FILE%.*}"
APP_CONFIG="${APP_DIR}/${APP_NAME}.conf"

# Input/edit prompt
PROMPT_CMD="cmd> "
PROMPT_EDIT="edit> "

# Help/usage text explaining available commands (NOTE: masking errors as
# read will encounter EOF, which will trip error handler if left unmasked)
read -r -d '' HELP_COMMANDS <<- EOD || :
	rs, replace-string STR REP    Replace string STR with replacement REP
	re, replace-regex RE TMP      Match regular expression RE and replace
	                              matching string according to template TMP
	                              (e.g. re "([0-9]+)x([0-9]+)" "S\\1E\\2")
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
EOD


# --------------------------------------
#                                      -
#  Configuration                       -
#                                      -
# --------------------------------------

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


# --------------------------------------
#                                      -
#  Functions                           -
#                                      -
# --------------------------------------

# Print normal/hilite/good/warn/error/debug message [$*: message]
# NOTE: warnings/errors are NOT sent to stderr (as script is interactive)
function printn() { echo -e "$*"; }
function printh() { echo -e "\e[1m$*\e[0m"; }
function printg() { echo -e "\e[1;32m$*\e[0m"; }
function printw() { echo -e "\e[1;33m$*\e[0m"; }
function printe() { echo -e "\e[1;31m$*\e[0m"; }
function printd() { echo -e "\e[1;30m$*\e[0m"; }

# Ask user yes/no question [$1: question, $2: newline before ('true'/'false';
# default: 'true'), $3: newline after ('true'/'false'; default: 'false')]
# Return value: 0 == yes, 1 == no
function ask_yes_no() {
	local input result
	[[ "${2:-"true"}" == "true" ]] && echo
	echo -en "\e[1;33m$1 [y/n]:\e[0m "
	while true; do
		read -s -n 1 input
		case "${input}" in
			y|Y) echo -e "\e[1;33myes\e[0m"; result=0; break; ;;
			n|N) echo -e "\e[1;33mno\e[0m"; result=1; break; ;;
		esac
	done
	[[ "${3:-"false"}" == "true" ]] && echo
	return ${result}
}

# Ask user to hit ENTER to continue [$1: name of print function, $2: message]
# Return value: 0 == ENTER, 1 == CTRL+D
function ask_hit_enter() {
	"$1" "$2"
	read -s || return 1
	return 0
}

# Generate list of files in current directory [$1: name of target array, $2:
# recursive mode, $3: filter invert, $4: filter case, $5: filter pattern]
# NOTE:
# Using workaround to account for non-GNU find, which does NOT support option
# '-printf': without '-printf', find results are prepended with './', which
# messes up sorting (version sort in particular) and thus needs to be stripped
# BEFORE sorting is performed; leaving original solution as comment for future
# reference
function generate_file_list() {
	local _recursive_opts=() _filter_opts=()
	[[ "$2" == "false" ]] && _recursive_opts+=("-maxdepth" "1")
	[[ "$3" == "true" ]] && _filter_opts+=("-not")
	[[ "$4" == "true" ]] && _filter_opts+=("-name" "$5") || _filter_opts+=("-iname" "$5")
	#readarray -t "$1" < <(find . -mindepth 1 "${_recursive_opts[@]}" -type f "${_filter_opts[@]}" -printf "%P\n" | sort "${SORT_OPTS[@]}")
	readarray -t "$1" < <(find . -mindepth 1 "${_recursive_opts[@]}" -type f "${_filter_opts[@]}" | cut -c 3- | sort "${SORT_OPTS[@]}")
}

# Generate list of folders in current directory [$1: name of target array]
# NOTE:
# Using workaround to account for non-GNU find, which does NOT support option
# '-printf': without '-printf', find results are prepended with './', which
# messes up sorting (version sort in particular) and thus needs to be stripped
# BEFORE sorting is performed; leaving original solution as comment for future
# reference; using '-mindepth 1' to keep '.' out of find results
function generate_folder_list() {
	#readarray -t "$1" < <(find . -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort "${SORT_OPTS[@]}")
	readarray -t "$1" < <(find . -mindepth 1 -maxdepth 1 -type d | cut -c 3- | sort "${SORT_OPTS[@]}")
}

# Print array (one line per element) [$1: name of array, $2: display indices
# (true/false)]
function print_array() {
	local -n _array="$1"
	if [[ "$2" == "true" ]]; then
		local _i _iw
		_iw=${#_array[@]}; _iw=${#_iw}
		for (( _i=0; _i < ${#_array[@]}; _i++ )); do
			#printf "%0${_iw}d) %s\n" $((_i+1)) "${_array[_i]}"
			#printf "%-${_iw}d) %s\n" $((_i+1)) "${_array[_i]}"
			printf "%${_iw}d) %s\n" $((_i+1)) "${_array[_i]}"
		done
	else
		local _item
		for _item in "${_array[@]}"; do echo "${_item}"; done
	fi
}

# Copy array [$1: name of source array, $2: name of target array]
function copy_array() {
	local -n _srcarr="$1"
	local -n _dstarr="$2"
	_dstarr=("${_srcarr[@]}")
}

# Compare two arrays [$1: name of array 1, $2: name of array 2]
# Return value: 0 == equal, 1 == not equal
# NOTE: arrays are equal if same amount of items and all items match
function compare_arrays() {
	local -n _array1="$1"
	local -n _array2="$2"
	local _i
	(( ${#_array1[@]} == ${#_array2[@]} )) || return 1
	for (( _i=0; _i < ${#_array1[@]}; _i++ )); do
		[[ "${_array1[_i]}" == "${_array2[_i]}" ]] || return 1
	done
	return 0
}

# Print command about to be played back [$1: cmd, $2: delay]
# Return value: 0 == continue playback, 1 == abort playback
# NOTE:
# - 'if ! read ...; then if (( $? == 1 )); then ... fi; fi' will NOT work as
#   expected as $? will always be 0, thus second 'if' is never triggered (not
#   sure why); using 'read ... || { (( $? == 1 )) && ...; }' instead, which
#   works as expected
# - For delay == 0, 'read -t 0 ...' would return 1, which would trip CTRL+D
#   detection -> added shortcut (which relies on normalized delay argument,
#   e.g. '000.000' or '0.0' -> normalized to just '0') to bypass read calls
function playback_print() {
	local cmd="$1" delay="$2"
	[[ "${delay}" == "0" ]] && { echo "${PROMPT_CMD}${cmd}"; return 0; }				# shortcut for delay == 0
	echo -n "${PROMPT_CMD}"																# print command prompt
	read -s -t "${delay}" || { (( $? == 1 )) && return 1; }								# delay, detect CTRL-D (abort playback)
	echo -n "${cmd}"																	# print command
	read -s -t "${delay}" || { (( $? == 1 )) && return 1; }								# delay, detect CTRL-D (abort playback)
	echo
	return 0
}

# Split string into array [$1: string, $2: separator character, $3: escape
# character, $4: maximum items, $5: name of target array]
# NOTE:
# - Maximum items: splitting ends after this many items, rest of string is
#   stored as last item in array; set to 0 to disable (i.e. split untils EOS)
# - Escape character: character used for escaping (usually '\'); set to empty
#   string to disable escaping
function split_string() {
	local _string="$1" _schar="$2" _echar="$3" _maxitems="$4"
	local -n _dstarr="$5"; _dstarr=()
	local _i _char="" _item="" _items=0 _escape=0 _quote=0 _qchar=""
	for (( _i=0; _i < ${#_string}; _i++ )); do
		_char="${_string:_i:1}"
		if (( ${_escape} == 1 )); then
			_item+="${_char}"
			_escape=0
			continue
		fi
		if [[ -n "${_echar}" && "${_char}" == "${_echar}" ]] && (( ${_quote} == 0 )); then
			_escape=1
			continue
		fi
		if [[ "${_char}" == "\"" || "${_char}" == "'" ]]; then
			if (( ${_quote} == 0 )); then
				_qchar="${_char}"
				_quote=1
				continue
			elif [[ "${_char}" == "${_qchar}" ]]; then
				_quote=0
				continue
			fi
		fi
		if [[ "${_char}" == "${_schar}" ]] && (( ${_quote} == 0 )); then
			#[[ -n "${_item}" ]] && _dstarr+=("${_item}")
			_dstarr+=("${_item}")
			_item=""
			_items=$((_items + 1))
			if (( ${_maxitems} > 0 && ${_items} >= ${_maxitems} )); then
				_item="${_string:_i+1}"
				break
			fi
			continue
		fi
		_item+="${_char}"
	done
	[[ -n "${_item}" ]] && _dstarr+=("${_item}") || :									# '|| :' is required for this to work with 'set -e' (could use 'return 0' instead)
}

# Regular expression string replace [$1: input string, $2: regex to search
# for and replace, $3: replacement template, $4: name of output variable]
# NOTE:
# - Replacement template uses KDE's Kate's syntax format, for example:
#   string '10x04', regex '([0-9]{2})x([0-9]{2})', template 'S\1E\2'
#   -> output 'S10E04'
# - Replacing behavior is same as KDE's Kate with a minor difference:
#   references to non-existent groups are replaced with empty strings
#   (seemed more logical this way)
# - Does currently NOT account for group references with leading zeros
#   (e.g. '\001'); would require replacing '${BASH_REMATCH[_grpidx]:-}'
#   with '${BASH_REMATCH[$((10#_grpidx))]:-}'
# - Based on:
#   'Development/Shell/Playground/bash_regex_replace_all_occurrences.sh'
function replace_regex() {
	local _in="$1" _re="$2" _reptmp="$3"
	local -n _out="$4"; _out=""
	local _repstr _escape _grpidx _i _char _match
	if [[ -z "${_re}" ]]; then															# trivial case: empty regex -> output = input, no further processing
		_out="${_in}"
		return
	fi
	while [[ -n "${_in}" ]] && [[ "${_in}" =~ ${_re} ]]; do								# loop while there is still input left and regex matches
		_repstr=""; _escape=0; _grpidx=""												# generate replacement string from replacement template and regex matches
		for (( _i=0; _i < ${#_reptmp}; _i++ )); do										# by processing template character by character
			_char="${_reptmp:${_i}:1}"
			if (( ${_escape} == 1 )); then												# if escaping is active and current character is ...
				if [[ "${_char}" == [0-9] ]]; then										# ... a digit:
					_grpidx+="${_char}"													# found group reference (e.g. '\12') -> add digit to group index, cycle loop
					continue
				elif [[ "${_char}" == "\\" ]]; then										# ... a backslash:
					if (( ${#_grpidx} > 0 )); then										# if there is a group index: found backslash after group reference (e.g. '\12\')
						_repstr+="${BASH_REMATCH[_grpidx]:-}"							# -> add group match to output, reset group index, leave escaping active
						_grpidx=""
					else																# if there is no group index: found escaped backslash (i.e. '\\')
						_repstr+="\\"													# -> add backslash to output, disable escaping
						_escape=0
					fi
					continue															# cycle loop
				else																	# ... something else:
					if (( ${#_grpidx} > 0 )); then										# if there is a group index: found end of group reference (e.g. '\12x' at 'x')
						_repstr+="${BASH_REMATCH[_grpidx]:-}"							# -> add group match to output
					else																# if there is no group index: found non-group-reference escape sequence (e.g. '\r')
						_repstr+="\\"													# -> add backslash to output
					fi
					_escape=0															# disable escaping, continue normally
				fi
			fi
			if [[ "${_char}" = "\\" ]]; then											# if current character is a backslash: found start of escape sequence (i.e. '\...')
				_escape=1																# -> enable escaping, reset group index, cycle loop
				_grpidx=""
				continue
			fi
			_repstr+="${_char}"															# add current character to replacement string
		done
		if (( ${_escape} == 1 )); then													# same as 'something else' above for end of template (condensed to single line)
			(( ${#_grpidx} > 0 )) && _repstr+="${BASH_REMATCH[_grpidx]:-}" || _repstr+="\\" # '||' part: treat trailing backslash as literal backslash
		fi

		_match="${BASH_REMATCH[0]}"														# substring matching ENTIRE regex -> to be replaced with replacement string
		if [[ "${_re:0:1}" == "^" ]]; then												# special handling for regex starting with '^' (e.g. re='^' or re='^.')
			_out="${_repstr}${_in#*"${_match}"}"										# output is replacement string + substring after match
			_in=""																		# no futher input, break loop
			break
		elif [[ "${_re: -1}" == "\$" ]]; then											# special handling for regex ending with '$' (e.g. re='$' or re='.$')
			_out="${_in%"${_match}"*}${_repstr}"										# output is substring before match + replacement string
			_in=""																		# no futher input, break loop
			break
		fi
		if [[ -z "${_match}" ]]; then													# if match is empty, prevent endless loop by advancing processing by the smallest
			_out+="${_in:0:1}"															# amount possible (i.e. move one character from input to output and cycle loop);
			_in="${_in:1}"																# empty matches are quite common, e.g. in='abc123def457ghi', re='[0-9]*'
			continue
		fi
		_out+="${_in%%"${_match}"*}${_repstr}"											# add substring before match + replacement string to output
		_in="${_in#*"${_match}"}"														# substring after match is input for next loop iteration
	done
	_out+="${_in}"																		# add remainder of input string to output
}

# Replace single dots with spaces [$1: string, $2: name of output variable]
function replace_dots() {
	local _in="$1"
	local -n _out="$2"; _out=""
	local _i _j _char="" _dots=0
	for (( _i=0; _i < ${#_in}; _i++ )); do
		_char="${_in:_i:1}"
		if [[ "${_char}" == "." ]]; then
			_dots=$((_dots + 1))
			continue
		else
			(( ${_dots} == 1 )) && _out+=" " || for ((_j=0; _j < _dots; _j++)); do _out+="."; done
			_dots=0
		fi
		_out+="${_char}"
	done
	(( ${_dots} == 1 )) && _out+=" " || for ((_j=0; _j < _dots; _j++)); do _out+="."; done
}

# Save macro to macro file [$1: macro file, $2: macro name, $3..$n: macro
# contents]
# Return value:
#   0 == macro saved (when saving) / macro deleted (when deleting)
#   1 == error occurred
#   2 == saving aborted (when saving) / macro not found (when deleting)
# NOTE: if NO macro contents are provided, macro is DELETED from macro file
function save_macro() {
	local file="$1" name="$2" contents=("${@:3}")
	local lines=() i starti=-1 endi=-1
	if [[ -f "${file}" ]]; then
		readarray -t lines < "${file}" || return 1
		for ((i=0; i < "${#lines[@]}"; i++)); do
			if (( ${starti} == -1 )); then
				[[ "${lines[i]}" == "[${name}]" ]] && starti=$i							# '[...]' -> start of macro
				continue
			fi
			[[ "${lines[i]}" == "" ]] && { endi=$i; break; }							# empty line -> end of macro
		done
	fi
	if (( ${#contents[@]} > 0 )); then													# macro non-empty? -> replace or append macro
		contents=("${contents[@]//"["/"\["}"); contents=("${contents[@]//"]"/"\]"}")	# escape square brackets
		if (( ${starti} != -1 && ${endi} != -1 )); then
			ask_yes_no "Macro '${name}' already exists. Overwrite?" "false" || return 2	# replace macro
			lines=("${lines[@]:0:starti}" "[${name}]" "${contents[@]}" "" "${lines[@]:endi+1}")
		else
			lines+=("[${name}]")														# append macro
			lines+=("${contents[@]}")
			lines+=("")
		fi
	else																				# no macro contents -> delete macro
		(( ${starti} != -1 && ${endi} != -1 )) || return 2								# macro not found
		lines=("${lines[@]:0:starti}" "${lines[@]:endi+1}")								# delete macro
	fi
	mkdir -p -- "$(dirname -- "${file}")" && printf "%s\n" "${lines[@]}" > "${file}" || return 1
	return 0
}

# Load macro from macro file [$1: macro file, $2: macro name, $3: name of
# target array (macro contents)]
# Return value: 0 == macro loaded, 1 == error occurred, 2 == macro not found
function load_macro() {
	local _file="$1" _name="$2"
	local -n _dstarr="$3" #; _dstarr=()
	local _line _contents=() _gotit="false"
	#[[ ! -f "${_file}" ]] && return 1													# no macro file -> nothing to load macro from (DISABLED as this would mask errors)
	while read -r _line; do
		if [[ "${_gotit}" == "false" ]]; then
			[[ "${_line}" == "[${_name}]" ]] && _gotit="true"							# '[...]' -> start of macro
			continue
		fi
		[[ "${_line}" == "" ]] && break													# empty line -> end of macro
		_line="${_line//"\["/"["}"; _line="${_line//"\]"/"]"}"							# unescape square brackets
		_contents+=("${_line}")
	done < "${_file}" || return 1
	[[ "${_gotit}" == "false" ]] && return 2											# macro not found
	_dstarr=("${_contents[@]}")															# assign macro contents to target variable
	return 0
}

# Delete macro from macro file  [$1: macro file, $2: macro name]
# Return value: 0 == macro deleted, 1 == error occurred, 2 == macro not found
# NOTE: convenience wrapper for 'save_macro()' for the sake clarity
function delete_macro() {
	save_macro "$1" "$2" && return $? || return $?
}

# List macros stored in macro file [$1: macro file, $2: name of target array
# (to store listing lines)]
# Return value: 0 == output generated, 1 == error occurred
function list_macros() {
	local _file="$1"
	local -n _dstarr="$2" #; _dstarr=()
	local _line _output=()
	#[[ ! -f "${_file}" ]] && return 0													# no macro file -> no macros to list (DISABLED as this would mask errors)
	while read -r _line; do
		[[ "${_line}" =~ ^\[(.+)\]$ ]] && { _output+=("Macro '${BASH_REMATCH[1]}':"); continue; }
		_line="${_line//"\["/"["}"; _line="${_line//"\]"/"]"}"							# unescape square brackets
		_output+=("${_line}")
	done < "${_file}" || return 1
	_dstarr=("${_output[@]::${#_output[@]}-1}")											# assign output to target variable, exclude last line (which is empty)
	return 0
}


# --------------------------------------
#                                      -
#  Initialization                      -
#                                      -
# --------------------------------------

# Usage information requested? (NOTE: this refers to the command line usage
# information, NOT to the interactive commands usage information, which may
# be displayed via command 'help'/'usage')
if [[ -n "${1+set}" ]] && [[ "$1" == "-h" || "$1" == "--help" ]]; then
	printn "\e[1mUsage:\e[0m ${0##*/} [INITIAL-DIRECTORY] [CMD]..."
	printn "\e[1mNote:\e[0m  Commands are executed right after startup"
	exit 0
fi

# Load configuration from file
if ! source "${APP_CONFIG}"; then
	printe "Error: failed to load configuration from '${APP_CONFIG}', aborting."
	exit 1
fi

# Process command line (TODO: implement command line parser and offer command
# line options to allow changing all items currently configurable via config
# file -> augment config variables)
[[ -n "${1+set}" ]] && { INITIAL_DIRECTORY="$1"; shift; }

#
# TODO:
# Check, verify and normalize config settings/items here; sort options can be
# verified by running 'sort "${SORT_OPTS[@]}" <<< ""' and checking exit code;
# especially needed for PLAYBACK_DELAY, which needs to be normalized before
# being passed to 'playback_print()'
#

# Change directory to initial directory (if specified/set) and then run 'cd .'
# to reset initial destination of 'cd -'
if [[ "${INITIAL_DIRECTORY}" != "" ]] && ! cd -- "${INITIAL_DIRECTORY}"; then
	printe "Error: failed to change to initial directory '${INITIAL_DIRECTORY}', aborting."; exit 1
fi
cd .

# Load command history from file (if enabled)
if [[ "${PERSISTENT_HISTORY}" == "true" && -f "${HISTORY_FILE}" ]]; then
	history -r -- "${HISTORY_FILE}" || { printe "Error: failed to load command history from '${HISTORY_FILE}', aborting."; exit 1; }
fi

# Initialize reset lists flag
reset_lists="true"

# Initialize error/info message storage
errors=()
infos=()

# Initialize macro storage/state
macro_storage=()
macro_record="false"

# Initialize filter state
filter_pattern="${FILTER_PATTERN}"
filter_invert="${FILTER_INVERT}"
filter_case="${FILTER_CASE}"

# Initialize recursive mode state
recursive_mode="${RECURSIVE_MODE}"

# Initialize command playback buffer/state, set up playback of commands
# specified on command line
playback_delay="${PLAYBACK_DELAY}"
playback_buffer=("$@")
playback_index=0
(( ${#playback_buffer[@]} > 0 )) && playback_enabled="true" || playback_enabled="false"

# Set up exit handler (for cosmetic reasons) and CTRL+C handler (for read
# calls, see https://stackoverflow.com/a/63713771/1976617)
trap "printn" EXIT
trap ":" INT


# --------------------------------------
#                                      -
#  Main                                -
#                                      -
# --------------------------------------

# Command input loop
infos=("Enter 'help' to display available commands.")
while true; do

	# Clear screen and print application header
	clear
	printh "--==[ ${APP_TITLE} v${APP_VERSION} ]==--"
	printn

	# Reset folder and file lists if requested
	if [[ "${reset_lists}" == "true" ]]; then
		generate_folder_list folders
		generate_file_list files_in "${recursive_mode}" "${filter_invert}" "${filter_case}" "${filter_pattern}"
		copy_array files_in files_out
		copy_array files_out files_undo
		copy_array files_out files_backup												# back up file list (allows undo/redo of played back commands up to last reset -or- macro play start)
		reset_lists="false"
	fi

	# List files and folders, print cwd
	printh "Files (${#files_out[@]}):"
	(( ${#files_out[@]} > 0 )) && print_array files_out true || printn "<no files>"
	printn
	printh "Folders (${#folders[@]}):"
	(( ${#folders[@]} > 0 )) && print_array folders false || printn "<no folders>"
	printn
	printh "Path (CWD):"
	pwd
	printn

	# Display error/info messages
	if (( ${#errors[@]} > 0 )); then
		for line in "${errors[@]}"; do printe "${line}"; done
		printn
		errors=()
	fi
	if (( ${#infos[@]} > 0 )); then
		for line in "${infos[@]}"; do printw "${line}"; done
		printn
		infos=()
	fi

	# Currently playing back commands?
	if [[ "${playback_enabled}" == "false" ]]; then
		# Prompt user for command input
		input=$(read -e -r -p "${PROMPT_CMD}" input && echo "${input}") || {			# https://stackoverflow.com/a/63713771/1976617
			case $? in
				  1) echo -e "\e[A\e[2K${PROMPT_CMD}ctrl+d (exit)"; input="exit"; ;;	# CTRL+D is treated same as 'exit'/'quit' (i.e. graceful exit)
				130) echo -e "\r\e[2K${PROMPT_CMD}ctrl+c (abort)"; break; ;;			# CTRL+C exits right away (ignoring unsaved changes)
			esac
		}
		[[ "${input}" == "" ]] && continue												# take shortcut if there was no input
		[[ "${input}" != "exit" && "${input}" != "quit" ]] && history -s -- "${input}"	# add input to history
	else
		# End of playback buffer reached?
		if (( ${playback_index} >= ${#playback_buffer[@]} )); then
			infos=("Command playback finished (${#playback_buffer[@]} commands).")
			playback_enabled="false"
			playback_buffer=()
			copy_array files_backup files_undo											# write file list backup to undo list (allows undo/redo of played back commands up to last reset -or- macro play start)
			continue
		fi

		# Use next item from buffer as command input
		printw "Playing back commands (command $((playback_index+1)) of ${#playback_buffer[@]}, delay ${playback_delay}s), hit CTRL+D to abort..."
		printn																			# using 'printw' instead of 'infos' here to have only one single place where this needs to be done
		input="${playback_buffer[${playback_index}]}"
		playback_index=$((playback_index + 1))
		if ! playback_print "${input}" "${playback_delay}"; then						# CTRL+D -> abort playback
			infos=("Command playback aborted (at command ${playback_index} of ${#playback_buffer[@]}).")
			playback_enabled="false"
			playback_buffer=()
			copy_array files_backup files_undo											# write file list backup to undo list (allows undo/redo of played back commands up to last reset -or- macro play start)
			continue
		fi
	fi

	# Evaluate command input
	split_string "${input}" " " "" 0 array												# split input into array, escaping disabled
	cmd="${array[0]}"; args=("${array[@]:1}")											# slice array into command and arguments
	case "${cmd}" in
		# Editing commands
		replace-string|rs| \
		replace-regex|re| \
		prepend|pre|pr| \
		append|post|po| \
		replace-dots|rd| \
		insert-dash|id| \
		capitalize|ca| \
		uppercase|upper|up| \
		lowercase|lower|lo| \
		trim|tr|strip|st)																# all of these commands affect file names
			[[ "${macro_record}" == "true" ]] && macro_storage+=("${input}")			# add raw input to macro if currently recording
			copy_array files_out files_undo												# save undo data
			for (( i=0; i < ${#files_out[@]}; i++ )); do
				[[ -n "${error+set}" ]] && break										# break loop if error was set in previous iteration
				file="${files_out[i]}"
				[[ "${file}" == */* ]] && dir="${file%/*}/" || dir=""					# extract leading directory part if existing
				#name="${file##*/}"
				name="${file##*/}"; name="${name%.*}"									# extract file name part (without directory and extension)
				[[ "${file}" == *.* ]] && ext=".${file##*.}" || ext=""					# extract trailing extension part if existing
				case "${cmd}" in
					replace-string|rs)
						if (( ${#args[@]} < 1 || ${#args[@]} > 2 )); then
							errors=("Error: replace-string: invalid number of arguments (expected 1 or 2, got ${#args[@]})")
							continue
						fi
						name="${name//"${args[0]}"/"${args[1]:-}"}"						# using '${args[1]:-}' to not trip 'set -u' for optional argument
						;;
					replace-regex|re)
						if (( ${#args[@]} < 1 || ${#args[@]} > 2 )); then
							errors=("Error: replace-regex: invalid number of arguments (expected 1 or 2, got ${#args[@]})")
							continue
						fi
						replace_regex "${name}" "${args[0]}" "${args[1]:-}" name		# using '${args[1]:-}' to not trip 'set -u' for optional argument
						;;
					prepend|pre|pr)
						if (( ${#args[@]} != 1 )); then
							errors=("Error: prepend: invalid number of arguments (expected 1, got ${#args[@]})")
							continue
						fi
						name="${args[0]}${name}"
						;;
					append|post|po)
						if (( ${#args[@]} != 1 )); then
							errors=("Error: append: invalid number of arguments (expected 1, got ${#args[@]})")
							continue
						fi
						name="${name}${args[0]}"
						;;
					replace-dots|rd)
						replace_dots "${name}" name
						;;
					insert-dash|id)
						re="([^[:space:]]+)[[:space:]]+(.*)"
						#[[ "${name}" =~ $re && "${BASH_REMATCH[1]: -1}" != "-" && "${BASH_REMATCH[2]:0:1}" != "-" ]] && name="${BASH_REMATCH[1]} - ${BASH_REMATCH[2]}"
						[[ "${name}" =~ $re && "${BASH_REMATCH[1]: -1}" != "-" && "${BASH_REMATCH[2]:0:1}" != "-" ]] && name="${name//"${BASH_REMATCH[0]}"/"${BASH_REMATCH[1]} - ${BASH_REMATCH[2]}"}"
						;;
					capitalize|ca)
						name_new=""
						for word in ${name}; do
							char="${word:0:1}"
							word="${char^^}${word:1:${#word}}"
							(( ${#name_new} == 0 )) && name_new="$word" || name_new="${name_new} ${word}"
						done
						name="${name_new}"
						;;
					uppercase|upper|up)
						name="${name^^}"
						ext="${ext^^}"
						;;
					lowercase|lower|lo)
						name="${name,,}"
						ext="${ext,,}"
						;;
					trim|tr|strip|st)
						name="${name#"${name%%[![:space:]]*}"}"							# trim leading whitespace
						name="${name%"${name##*[![:space:]]}"}"							# trim trailing whitespace
						;;
				esac
				#files_out[i]="${dir}${name}"
				files_out[i]="${dir}${name}${ext}"
			done
			;;

		# Macro commands (1)
		record-macro|rm)
			if [[ "${macro_record}" == "false" ]]; then
				macro_record="true"
				(( ${#macro_storage[@]} > 0 )) && infos=("Macro recording started (adding to existing contents).") || infos=("Macro recording started (macro is empty).")
			else
				macro_record="false"
				if (( ${#macro_storage[@]} > 0 )); then
					infos=("Macro recording stopped. Macro contents:")
					for line in "${macro_storage[@]}"; do infos+=("${line}"); done
				else
					infos=("Macro recording stopped (macro is empty).")
				fi
			fi
			;;
		view-macro|vm)
			if (( ${#macro_storage[@]} > 0 )); then
				[[ "${macro_record}" == "true" ]] && infos=("Macro contents (still recording):") || infos=("Macro contents:")
				for line in "${macro_storage[@]}"; do infos+=("${line}"); done
			else
				[[ "${macro_record}" == "true" ]] && infos=("Macro is empty (still recording).") || infos=("Macro is empty.")
			fi
			;;
		clear-macro|cm)
			macro_storage=()
			[[ "${macro_record}" == "true" ]] && infos=("Macro contents cleared (still recording).") || infos=("Macro contents cleared.")
			;;
		play-macro|pm)
			if [[ "${macro_record}" == "true" ]]; then
				errors=("Error: play-macro: can't play back macro while recording")
				continue
			fi
			if (( ${#macro_storage[@]} == 0 )); then
				errors=("Error: play-macro: can't play back empty macro")
				continue
			fi
			if [[ "${playback_enabled}" == "true" ]]; then								# already playing back commands? -> inject macro contents into existing playback buffer stream
				playback_buffer=("${playback_buffer[@]::${playback_index}}" "${macro_storage[@]}" "${playback_buffer[@]:${playback_index}}")
			else																		# currently not playing back commands -> set up and start command playback
				copy_array files_out files_backup										# back up current file list to allow undo/redo of ENTIRE macro (see 'End of playback buffer reached?' above)
				playback_buffer=("${macro_storage[@]}")
				playback_index=0
				playback_enabled="true"
			fi
			infos=("Starting playback of macro (${#macro_storage[@]} commands).")
			;;
		playback-delay|pd)
			if (( ${#args[@]} != 1 )); then
				errors=("Error: playback-delay: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if ! [[ "${args[0]}" =~ ^[0-9]+$ || "${args[0]}" =~ ^[0-9]+\.[0-9]+$ ]]; then
				errors=("Error: playback-delay: value argument must be positive integer or fraction")
				continue
			fi
			if [[ "${args[0]}" =~ ^[0]+$ || "${args[0]}" =~ ^[0]+\.[0]+$ ]]; then		# if specified delay == 0 (might be '000', '0.0' or '00.00') ...
				playback_delay="0"														# ... normalize to just '0' for easier handling within 'playback_print()'
			else
				playback_delay="${args[0]}"
			fi
			infos=("Command playback delay set to ${playback_delay}s.")
			;;

		# Macro commands (2)
		save-macro|sm)
			if (( ${#args[@]} != 1 )); then
				errors=("Error: save-macro: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if [[ "${args[0]}" == "" ]]; then
				errors=("Error: save-macro: name argument must not be empty")
				continue
			fi
			if (( ${#macro_storage[@]} == 0 )); then
				errors=("Error: save-macro: can't save empty macro")
				continue
			fi
			name="${args[0]}"; printn
			if save_macro "${MACROS_FILE}" "${name}" "${macro_storage[@]}"; then
				infos=("Saved macro '${name}' (${#macro_storage[@]} commands).")
			else
				if (( $? == 2 )); then
					infos=("Saving macro '${name}' was aborted.")
					continue
				fi
				#errors=("Error: save-macro: failed to save macro '${name}'")
				printn; ask_hit_enter printe "Error: save-macro: failed to save macro '${name}', hit ENTER to continue" || :
			fi
			;;
		load-macro|lm)
			if (( ${#args[@]} != 1 )); then
				errors=("Error: load-macro: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if [[ "${args[0]}" == "" ]]; then
				errors=("Error: load-macro: name argument must not be empty")
				continue
			fi
			if (( ${#macro_storage[@]} > 0 )); then
				ask_yes_no "Macro is non-empty, contents will be replaced. Continue?" || continue
			fi
			name="${args[0]}"; printn
			if load_macro "${MACROS_FILE}" "${name}" macro_storage; then
				infos=("Loaded macro '${name}':")
				for line in "${macro_storage[@]}"; do infos+=("${line}"); done
			else
				if (( $? == 2 )); then
					errors=("Error: load-macro: no macro named '${name}' found")
					continue
				fi
				#errors=("Error: load-macro: failed to load macro '${name}'")
				printn; ask_hit_enter printe "Error: load-macro: failed to load macro '${name}', hit ENTER to continue" || :
			fi
			;;
		delete-macro|dm)
			if (( ${#args[@]} != 1 )); then
				errors=("Error: delete-macro: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if [[ "${args[0]}" == "" ]]; then
				errors=("Error: delete-macro: name argument must not be empty")
				continue
			fi
			name="${args[0]}"; printn
			if delete_macro "${MACROS_FILE}" "${name}"; then
				infos=("Deleted macro '${name}'.")
			else
				if (( $? == 2 )); then
					errors=("Error: delete-macro: no macro named '${name}' found")
					continue
				fi
				#errors=("Error: delete-macro: failed to delete macro '${name}'")
				printn; ask_hit_enter printe "Error: delete-macro: failed to delete macro '${name}', hit ENTER to continue" || :
			fi
			;;
		list-macros|im)
			printn
			if list_macros "${MACROS_FILE}" infos; then
				#(( ${#infos[@]} > 0 )) || infos=("No macros stored in macro file.")
				(( ${#infos[@]} > 0 )) && infos=("Macros stored in macro file:" "" "${infos[@]}") || infos=("No macros stored in macro file.")
			else
				#errors=("Error: list-macros: failed to list macros")
				printn; ask_hit_enter printe "Error: list-macros: failed to list macros, hit ENTER to continue" || :
			fi
			;;

		# History commands
		history-macro|hm)
			if [[ "${macro_record}" == "true" ]]; then
				errors=("Error: history-macro: can't create macro from history while recording macro")
				continue
			fi
			macro_storage=()
			re="^[0-9]+[* ] ([^[:space:]]+)(.*)$"										# all this relies on IFS containing space character (!)
			while read -r line; do
				if [[ "${line}" =~ ${re} ]]; then
					case "${BASH_REMATCH[1]}" in
						replace-string|rs| \
						replace-regex|re| \
						prepend|pre|pr| \
						append|post|po| \
						replace-dots|rd| \
						insert-dash|id| \
						capitalize|ca| \
						uppercase|upper|up| \
						lowercase|lower|lo| \
						trim|tr|strip|st) macro_storage+=("${BASH_REMATCH[1]}${BASH_REMATCH[2]}"); ;;
					esac
				fi
			done < <(history)
			if (( ${#macro_storage[@]} > 0 )); then
				infos=("Created macro from history:")
				for line in "${macro_storage[@]}"; do infos+=("${line}"); done
			else
				errors=("Error: history-macro: no editing commands in history to create macro from")
			fi
			;;
		view-history|vh)
			infos=("Command history:")
			while read -r line; do infos+=("${line}"); done < <(history)				# auto-trims output (relies on IFS containing space character)
			;;
		clear-history|ch)
			history -c
			infos=("Command history cleared.")
			;;

		# Filter commands
		filter-pattern|fp)
			if (( ${#args[@]} != 1 )); then
				errors=("Error: filter-pattern: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Continue anyway?" || continue	# ... prompt user before continuing
			fi
			filter_pattern="${args[0]}"
			reset_lists="true"
			infos=("Filter pattern set to '${filter_pattern}'.")
			;;
		invert-filter|if)
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Continue anyway?" || continue	# ... prompt user before continuing
			fi
			[[ "${filter_invert}" == "false" ]] && filter_invert="true" || filter_invert="false"
			reset_lists="true"
			#infos=("Filter invert set to '${filter_invert}'.")
			[[ "${filter_invert}" == "false" ]] && infos=("Filter invert disabled.") || infos=("Filter invert enabled.")
			;;
		filter-case|fc)
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Continue anyway?" || continue	# ... prompt user before continuing
			fi
			[[ "${filter_case}" == "false" ]] && filter_case="true" || filter_case="false"
			reset_lists="true"
			#infos=("Filter case set to '${filter_case}'.")
			[[ "${filter_case}" == "false" ]] && infos=("Filter set to case insensitive.") || infos=("Filter set to case sensitive.")
			;;
		view-filter|vf)
			#infos=("Filter state: pattern: '${filter_pattern}', invert: ${filter_invert}, case: ${filter_case}")
			infos=("Filter state: pattern: '${filter_pattern}'")
			[[ "${filter_invert}" == "false" ]] && infos[0]+=", invert: disabled" || infos[0]+=", invert: enabled"
			[[ "${filter_case}" == "false" ]] && infos[0]+=", case: insensitive" || infos[0]+=", case: sensitive"
			;;
		reset-filter|rf)
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Continue anyway?" || continue	# ... prompt user before continuing
			fi
			filter_pattern="*"
			filter_invert="false"
			filter_case="false"
			reset_lists="true"
			infos=("Filter reset.")
			;;

		# Edit/undo/recursive/chdir commands
		edit|ed)
			if (( ${#args[@]} != 1 )); then
				errors=("Error: edit: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if [[ ! "${args[0]}" =~ ^[0-9]+$ ]]; then									# '10#...' conversion below would error out on negative values
				errors=("Error: edit: index argument is not a positive integer (expected [0-9]+, got ${args[0]})")
				continue
			fi
			index=$((10#${args[0]}))													# deal with leading zeros (such values are interpreted as octal by default)
			if (( ${index} < 1 || ${index} > ${#files_out[@]} )); then
				errors=("Error: edit: index argument is out of range (expected 1-${#files_out[@]}, got ${index})")
				continue
			fi
			printn
			printw "Editing entry ${index} (hit CTRL+C to abort):"						# not mentioned but EMPTY input line + CTRL+D also aborts (see '|| continue' below)
			printn
			file="${files_out[index-1]}"
			[[ "${file}" == */* ]] && dir="${file%/*}/" || dir=""						# extract leading directory part if existing
			#name="${file##*/}"; name="${name%.*}"										# extract file name part (without directory and extension)
			#[[ "${file}" == *.* ]] && ext=".${file##*.}" || ext=""						# extract trailing extension part if existing
			name="${file##*/}"
			name=$(history -c; read -e -r -p "${PROMPT_EDIT}" -i "${name}" name && echo "${name}") || continue	# clear history in subshell to allow for clean editing
			copy_array files_out files_undo												# save undo data
			#files_out[index-1]="${dir}${name}${ext}"									# modify entry
			files_out[index-1]="${dir}${name}"											# modify entry
			;;
		undo|ud)
			if compare_arrays files_out files_undo; then								# if arrays match, there's nothing to undo
				errors=("Error: undo: nothing to undo")
				continue
			fi
			copy_array files_out files_temp												# this ...
			copy_array files_undo files_out												# undo last operation
			copy_array files_temp files_undo											# ... and this allows to undo undo
			unset files_temp
			;;
		rc|recursive)
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Continue anyway?" || continue	# ... prompt user before continuing
			fi
			[[ "${recursive_mode}" == "false" ]] && recursive_mode="true" || recursive_mode="false"
			reset_lists="true"
			#infos=("Recursive mode set to '${recursive_mode}'.")
			[[ "${recursive_mode}" == "false" ]] && infos=("Recursive mode disabled.") || infos=("Recursive mode enabled.")
			;;
		chdir|cd)
			split_string "${input}" " " "\\" 0 array									# split input into array again, this time with escaping enabled
			args=("${array[@]:1}")														# fetch arguments from array, drop array[0] containing cmd
			if (( ${#args[@]} != 1 )); then												# check number of arguments
				errors=("Error: chdir: invalid number of arguments (expected 1, got ${#args[@]})")
				continue
			fi
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Continue anyway?" || continue	# ... prompt user before continuing
			fi
			dir="${args[0]}"
			[[ "${dir}" == "~" || "${dir}" == "~/"* ]] && dir="${HOME}${dir#\~}"		# replace leading '~' with $HOME if present
			if cd -- "${dir}"; then														# change directory
				reset_lists="true"														# request lists reset
			else
				errors=("Error: chdir: failed to change directory to '${dir}'")
			fi
			;;

		# Apply/reset commands
		apply|save)
			printn
			printw "Applying changes..."
			errcnt=0
			for (( i=0; i < ${#files_in[@]}; i++ )); do
				src="${files_in[i]}"
				dst="${files_out[i]}"
				[[ "${src}" == "${dst}" ]] && continue									# path/name unchanged -> continue
				if [[ -e "${dst}" ]]; then												# if destination already exists ...
					name="${dst%.*}"													# ... split into name ...
					[[ "${dst}" == *.* ]] && ext=".${dst##*.}" || ext=""				# ... and extension, ...
					for (( j=1; ; j++ )); do											# CAUTION: could result in a endless loop on overflow due to LOTS of files
						dst="${name}_${j}${ext}"										# ... add postfix to name ('_1', '_2', etc.) ...
						[[ ! -e "${dst}" ]] && break									# ... and break once collision is resolved
					done
				fi
				# NOTE:
				# Should the need arise to move files to different directories (e.g. due to
				# directory part becoming editable), something like this would do the trick
				# (draft only, likely needs additional checks for edge cases; probably best
				# to wrap this in a function to allow for rollback in case of errors):
				#mkdir -p -- "$(dirname -- "${dst}")" && mv -i -- "${src}" "${dst}" && rmdir --parents --ignore-fail-on-non-empty -- "$(dirname -- "${src}")" || errcnt=$((errcnt + 1))
				mv -i -- "${src}" "${dst}" || errcnt=$((errcnt + 1))					# rename file, count errors
			done
			if (( ${errcnt} == 0 )); then
				infos=("Succesfully renamed ${#files_in[@]} file(s).")
			else																		# prompt user if error(s) occurred when renaming file(s)
				#errors=("Error: failed to rename ${errcnt} file(s)")
				printn; ask_hit_enter printe "Error: failed to rename ${errcnt} file(s), hit ENTER to continue" || :
			fi
			reset_lists="true"															# request lists reset
			;;
		reload|reset)
			#generate_folder_list folders												# this block would allow to undo reset ...
			#copy_array files_out files_undo											# ... disabled but keeping it for future reference
			#generate_file_list files_in
			#copy_array files_in files_out
			reset_lists="true"															# request lists reset
			;;

		# Help/exit commands
		help|usage)
			infos=("Available commands:")
			infos+=("${HELP_COMMANDS}")
			;;
		exit|quit)
			if ! compare_arrays files_in files_out; then								# if there are unsaved changes ...
				ask_yes_no "There are unsaved changes. Exit anyway?" || continue		# ... prompt user before continuing
			fi
			break																		# exit/quit by breaking outer loop
			;;

		"#"*)																			# allows to disable commands using leading '#'
			continue
			;;
		*)
			errors=("Error: invalid command '${cmd}'")
			;;
	esac

done

# Save command history to file (if enabled)
if [[ "${PERSISTENT_HISTORY}" == "true" ]]; then
	#mkdir -p -- "$(dirname -- "${HISTORY_FILE}")" && history -w -- "${HISTORY_FILE}" || { printn; printe "Error: failed to save command history to '${HISTORY_FILE}'"; exit 1; }
	mkdir -p -- "$(dirname -- "${HISTORY_FILE}")" && history -w -- "${HISTORY_FILE}" || { printn; printe "Error: failed to save command history to '${HISTORY_FILE}'"; }
fi

# Return home safely
exit 0
