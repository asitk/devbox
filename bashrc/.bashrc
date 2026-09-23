#!/bin/bash

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Silence Apple's default shell deprecation warning natively on macOS environments
if [[ "$OSTYPE" == "darwin"* ]]; then
	export BASH_SILENCE_DEPRECATION_WARNING=1
fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	# shellcheck disable=SC1091
	. /etc/bashrc
fi

# Detect Operating System
OS_TYPE="$(uname)"

# User specific environment
# Helper function for exact PATH matching
path_exists() {
	[[ ":$PATH:" == *":$1:"* ]]
}

# Add $HOME/.local/bin if not already in PATH (prepended)
if ! path_exists "$HOME/.local/bin"; then
	PATH="$HOME/.local/bin:$PATH"
fi

# Add $HOME/bin if not already in PATH (prepended)
if ! path_exists "$HOME/bin"; then
	PATH="$HOME/bin:$PATH"
fi

# Add Cargo bin path if not already in PATH
if ! path_exists "$HOME/.cargo/bin"; then
	export PATH="$HOME/.cargo/bin:$PATH"
fi

# Linux-Specific Flatpak Paths
if [[ "$OS_TYPE" == "Linux" ]]; then
	if ! path_exists "/var/lib/flatpak/exports/bin"; then
		export PATH="/var/lib/flatpak/exports/bin:$PATH"
	fi
	if ! path_exists "$HOME/.local/share/flatpak/exports/bin"; then
		export PATH="$HOME/.local/share/flatpak/exports/bin:$PATH"
	fi
fi

# Dynamic Cross-Platform Homebrew Initialization
if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -f "/opt/homebrew/bin/brew" ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
	eval "$(/usr/local/bin/brew shellenv)"
elif [ -f "$HOME/.linuxbrew/bin/brew" ]; then
	# shellcheck disable=SC2086
	eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi

# Brew configuration with safe PATH additions
if command -v brew >/dev/null 2>&1; then
	# Add brew gnubin paths only if not already in PATH
	if ! path_exists "$(brew --prefix coreutils)/libexec/gnubin"; then
		coreutils_path="$(brew --prefix coreutils)/libexec/gnubin"
		export PATH="$coreutils_path:$PATH"
	fi

	if ! path_exists "$(brew --prefix gnu-sed)/libexec/gnubin"; then
		gnu_sed_path="$(brew --prefix gnu-sed)/libexec/gnubin"
		export PATH="$gnu_sed_path:$PATH"
	fi

	if ! path_exists "$(brew --prefix gnu-tar)/libexec/gnubin"; then
		gnu_tar_path="$(brew --prefix gnu-tar)/libexec/gnubin"
		export PATH="$gnu_tar_path:$PATH"
	fi

	# Add bash completion2 for bash >= 4.2
	if [[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]]; then
		# shellcheck disable=SC1091
		source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
	# Invoke bash completion for bash < 4.2
	elif [ -f "$(brew --prefix)/etc/bash_completion.sh" ]; then
		# shellcheck disable=SC1091
		. "$(brew --prefix)/etc/bash_completion.sh"
	fi
fi

export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			# shellcheck disable=SC1090
			. "$rc"
		fi
	done
fi
unset rc

# Run ssh-agent if not already running
if ! pgrep -u "$USER" ssh-agent >/dev/null; then
	eval "$(ssh-agent -s)"
fi

# Disable the bell
if [[ $- == *i* ]]; then bind "set bell-style visible"; fi

#######################################################
# EXPORTS
#######################################################

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T " # add timestamp to history

# Don't put duplicate lines in the history and do not add lines that \
# start with a space
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Check the window size after each command and, if necessary, update \
# the values of LINES and COLUMNS
shopt -s checkwinsize

# Causes bash to append to history instead of overwriting it so if you \
# start a new terminal, you have old session history
shopt -s histappend
PROMPT_COMMAND='history -a'

# set up XDG folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Allow ctrl-S for history navigation (with ctrl-R)
[[ $- == *i* ]] && stty -ixon

# Ignore case on auto-completion
# Note: bind used instead of sticking these in .inputrc
if [[ $- == *i* ]]; then bind "set completion-ignore-case on"; fi

# Show auto-completion list automatically, without double tab
if [[ $- == *i* ]]; then bind "set show-all-if-ambiguous On"; fi

# Set the default editor
if command -v nvim >/dev/null 2>&1; then
	export EDITOR=nvim
	export VISUAL=nvim
	alias vim='nvim'
	alias vi='nvim'
	alias e='nvim'
fi

# To have colors for ls and all grep commands such as grep, egrep and \
# zgrep
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Check if ripgrep is installed
if command -v rg &>/dev/null; then
	# Alias grep to rg if ripgrep is installed
	alias grep='rg'
else
	# Alias grep to /usr/bin/grep with GREP_OPTIONS if ripgrep is \
	# not installed
	alias grep="/usr/bin/grep"
fi

# Color for manpages in less makes manpages a little easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#######################################################
# ALIASES
#######################################################

# Edit this .bashrc file
alias ebsh='vi ~/.bashrc'
alias sbsh='source ~/.bashrc'
alias etmx='vi ~/.config/tmux/tmux.conf'
alias envm='vi ~/.config/nvim/init.lua'

# Copy file contents to Clipboard
cb() {
	if [[ "$OS_TYPE" == "Darwin" ]]; then
		cat "$1" | pbcopy
	else
		xclip -selection clipboard <"$1"
	fi
}

# alias to show the date
alias da='date "+%Y-%m-%d %A %T %Z"'

# Alias's to modified commands
alias c='clear'
alias cp='cp -i'
alias mv='mv -i'

# Safe delete
if command -v trash >/dev/null 2>&1; then
	alias rm='trash -v'
fi

alias mkdir='mkdir -p'
alias ps='ps auxf'
alias ping='ping -c 10'
alias less='less -R'
alias cls='clear'
alias multitail='multitail --no-repeat -c'
alias svi='sudo vi'
alias vis='nvim "+set si"'

if command -v bat >/dev/null 2>&1; then
	alias cat='bat'
fi

# Change directory aliases
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Alias's for multiple directory listing commands
if command -v eza >/dev/null 2>&1; then
	alias lx='eza -lhXB'          # sort by extension
	alias lk='eza -lhrs size'     # sort by size
	alias lc='eza -lhrs changed'  # sort by change time (recently changed first)
	alias lu='eza -lhrs accessed' # sort by access time (latest update first)
	alias lo='eza -lhs modified'  # sort by oldest first
	alias ln='eza -lhrs modified' # sort by newest first
	alias lr='eza -lhR'           # recursive ls
	alias lt='eza -lhtr'          # sort by date
	alias lm='eza -lha | less'    # pipe through 'less'
	alias lw='eza -xAh'           # wide listing format
	alias labc='eza -lhs name'    # alphabetical sort
	alias lf='eza -lhf'           # files only
	alias ld='eza -D'             # directories only
	alias lla='eza -Alh'          # List and Hidden Files
	alias lls='eza -lh'           # List

	alias la='eza -Ah --color=always --group-directories-first --icons'
	alias ls='eza --color=always --group-directories-first --icons'
	alias ll='eza -la --header --icons --git --group-directories-first'
	alias lt='eza --tree --level=2 --icons'
fi

# alias chmod commands
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# Search command line history
alias h="history | grep "

# Search running processes
alias p="ps aux | grep "

if [[ "$OS_TYPE" == "Darwin" ]]; then
	alias ps='ps aux'
	alias topcpu="ps -eo pcpu,pid,user,command | sort -k 1 -r | head -10"
else
	alias ps='ps auxf'
	alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
fi

# Search files in the current folder
alias f="find . | grep "

# Count all files (recursively) in the current folder
# shellcheck disable=SC2154
alias countfiles='for type in files links directories; do echo "$(find . -type ${type:0:1} | wc -l) $type"; done 2> /dev/null'

# To see if a command is aliased, a file, or a built-in command
alias checkcommand="type -t"

# Show open ports
if [ "$OS_TYPE" = "Darwin" ]; then
	alias openports='netstat -anp tcp | grep LISTEN'
else
	alias openports='netstat -nape --inet'
fi

# Alias's for safe and forced reboots
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# Alias's to show disk space and space used in a folder
alias diskspace="du -S | sort -n -r |more"

# Universal portable du flag changes
alias folders='du -h -d 1'
alias folderssort='find . -type d -maxdepth 1 -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -h'

# Alias's for archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Show all logs in /var/log
if [ "$OS_TYPE" = "Darwin" ]; then
	alias logs='echo "macOS logs: Use Console app or check /var/log/"'
else
	alias logs='sudo find /var/log -type f -exec file {} \; | grep "text" | cut -d" " -f1 | sed "s/://g" | xargs tail -f'
fi

# SHA1
alias sha1='openssl sha1'

# alias to cleanup unused docker containers, images, networks, and volumes
if command -v docker >/dev/null 2>&1; then
	alias docker-clean='docker container prune -f ; docker image prune -f ; docker network prune -f ; docker volume prune -f '
fi

#######################################################
# SPECIAL FUNCTIONS
#######################################################

# Runs any command in the background with nohup
r() {
	nohup "$@" >/dev/null 2>&1 &
}

# Extracts any archive(s) (if unp isn't installed)
extract() {
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			case $archive in
			*.tar.bz2) tar xvjf "$archive" ;;
			*.tar.gz) tar xvzf "$archive" ;;
			*.bz2) bunzip2 "$archive" ;;
			*.rar) rar x "$archive" ;;
			*.gz) gunzip "$archive" ;;
			*.tar) tar xvf "$archive" ;;
			*.tbz2) tar xvjf "$archive" ;;
			*.tgz) tar xvzf "$archive" ;;
			*.zip) unzip "$archive" ;;
			*.Z) uncompress "$archive" ;;
			*.7z) 7z x "$archive" ;;
			*) echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# Searches for text in all files recursively, bypassing broken global aliases
ftext() {
	if command -v rg &>/dev/null; then
		rg -i --color=always "$1" . | less -R
	else
		command grep -iIrn --color=always "$1" . | less -R
	fi
}

# Copy and go to the directory
cpg() {
	if [ -d "$2" ]; then
		cp "$1" "$2" && cd "$2" || return 1
	else
		cp "$1" "$2"
	fi
}

# Move and go to the directory
mvg() {
	if [ -d "$2" ]; then
		mv "$1" "$2" && cd "$2" || return 1
	else
		mv "$1" "$2"
	fi
}

# Create and go to the directory
mkdirg() {
	mkdir -p "$1"
	cd "$1" || return 1
}

# Modern pure-Bash path loop implementation that completely avoids parsing errors
# Goes up a specified number of directories  (i.e. up 4)
up() {
	local limit=${1:-1}
	local target="."
	local i
	for ((i = 0; i < limit; i++)); do
		target="${target}/.."
	done
	cd "$target" || return 1
}

# Automatically do an ls after each cd, z, or zoxide
cd() {
	if [ -n "$1" ]; then
		builtin cd "$@" && ls
	fi
}

# Returns the last 2 fields of the working directory
pwdtail() {
	pwd | awk -F/ '{nlast = NF -1; print $nlast"/"$NF}'
}

# IP address lookup
whatsmyip() {
	echo -n "Internal IP: "
	if [ "$OS_TYPE" = "Darwin" ]; then
		ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null
	else
		if command -v hostname >/dev/null 2>&1; then
			hostname -I | awk '{print $1}'
		else
			ifconfig | grep "inet " | awk '{print $2}' | head -1
		fi
	fi
	echo -n "External IP: "
	curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 ipinfo.io/ip 2>/dev/null
	echo ""
}

# GitHub Additions
gcom() {
	git add .
	git commit -m "$1"
}
lazyg() {
	git add .
	git commit -m "$1" && git push
}

# Check if the shell is interactive
if [[ $- == *i* ]]; then
	bind '"\C-f":"zi\n"'
fi

# Clean up helper function
unset -f path_exists

#######################################################
# STARSHIP, CD REPLACEMENT AND FUZZY SEARCH
#######################################################

if command -v starship >/dev/null 2>&1; then
	eval "$(starship init bash)"
fi
if command -v zoxide >/dev/null 2>&1; then
	eval "$(zoxide init --cmd cd bash)"
fi
if command -v fzf >/dev/null 2>&1; then
	eval "$(fzf --bash)"
fi

if command -v fzf >/dev/null 2>&1; then
	if command -v fd &>/dev/null; then
		export FZF_CTRL_T_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"
	elif command -v rg &>/dev/null; then
		export FZF_CTRL_T_COMMAND="rg --files --hidden --follow --glob '!/.git/*'"
	fi

	if command -v bat &>/dev/null && command -v eza &>/dev/null; then
		export FZF_CTRL_T_OPTS="
			--height 80% --layout reverse --border
			--prompt '🔍 Files > '
			--header '💡 [Ctrl-/] Toggle Preview | [Ctrl-Y] Copy Path'
			--preview 'if [ -d {} ]; then eza --tree --level=2 --icons --color=always {} 2>/dev/null; else bat --style=numbers --color=always --line-range :500 {} 2>/dev/null; fi'
			--preview-window 'right:55%:wrap'
			--bind 'ctrl-/:toggle-preview'
			--bind 'ctrl-y:execute-silent(echo -n {} | (pbcopy 2>/dev/null || xclip -selection clipboard))+abort'
		"
	else
		export FZF_CTRL_T_OPTS="
			--height 80% --layout reverse --border
			--prompt '🔍 Files > '
			--header '💡 [Ctrl-/] Toggle Preview | [Ctrl-Y] Copy Path'
			--preview 'if [ -d {} ]; then tree -C -L 2 {} 2>/dev/null || ls -F {}; else cat {} 2>/dev/null; fi'
			--preview-window 'right:55%:wrap'
			--bind 'ctrl-/:toggle-preview'
			--bind 'ctrl-y:execute-silent(echo -n {} | (pbcopy 2>/dev/null || xclip -selection clipboard))+abort'
		"
	fi

	export FZF_CTRL_R_OPTS="
		--preview 'echo {} | sed -E \"s/^[ ]*[0-9]+[ ]*//\"' --preview-window down:3:hidden:wrap
		--bind 'ctrl-/:toggle-preview'
		--bind 'ctrl-y:execute-silent(echo -n {} | sed -E \"s/^[ ]*[0-9]+[ ]*//\" | (pbcopy 2>/dev/null || xclip -selection clipboard))+abort'
		--color 'header:italic:underline'
		--header 'Press CTRL-Y to copy command, CTRL-/ to toggle preview'"

	# ========================================================
	# 🔍 Global FZF Custom Tab-Completion Engine (All Commands) [3]
	# ========================================================
	_fzf_comprun() {
		local command=$1
		shift

		case "$command" in
		export | unset)
			# shellcheck disable=SC2016
			fzf "$@" \
				--prompt "🔐 Variables > " \
				--preview 'eval echo \${}' \
				--preview-window 'right:50%:wrap'
			;;
		cd)
			fzf "$@" \
				--prompt "📂 Change Dir > " \
				--preview 'if command -v eza &>/dev/null; then eza --tree --level=2 --icons --color=always {} 2>/dev/null; else tree -C -L 2 {} 2>/dev/null || ls -F {}; fi' \
				--preview-window 'right:50%:wrap'
			;;
		kill)
			# FIXED: Uses BSD-safe process formatting rules to fully prevent macOS kill-menu panics [3]
			# shellcheck disable=SC2016
			fzf "$@" \
				--prompt "⚡ Kill Process > " \
				--preview 'ps -p {} -o comm,pcpu,pmem 2>/dev/null || ps -fp {} 2>/dev/null' \
				--preview-window 'bottom:3:wrap'
			;;
		ssh)
			fzf "$@" \
				--prompt "🌐 SSH Hosts > " \
				--preview 'grep -A 5 "Host {}" ~/.ssh/config 2>/dev/null || echo "No custom SSH config entry found for {}"' \
				--preview-window 'right:50%:wrap'
			;;
		*)
			fzf "$@" \
				--prompt "📄 Files > " \
				--preview 'if [ -d {} ]; then eza --tree --level=2 --icons --color=always {} 2>/dev/null || tree -C -L 2 {}; else bat --style=numbers --color=always --line-range :200 {} 2>/dev/null || cat {}; fi' \
				--preview-window 'right:55%:wrap' \
				--bind 'ctrl-/:toggle-preview'
			;;
		esac
	}
fi

# Linked cleanly beneath the zoxide runtime loader setup
alias zi='cdi'

# Load custom terminal configurations if the file exists
if [ -f ~/.bash_custom ]; then
	# shellcheck disable=SC1090
	. ~/.bash_custom
else
	# Load custom terminal configurations if the file exists
	if [ -f ~/.config/bash/bash_custom ]; then
		# shellcheck disable=SC1090
		. ~/.config/bash/bash_custom
	fi
fi
