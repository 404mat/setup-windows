# zmodload zsh/zprof # uncomment this and last file command to profile startup time

# sourcung oh-my-zsh config (if you move ohmyszh config to an exterman file)
# source $HOME/.ohmyzsh-config-custom

# Expand the history size
export HISTFILESIZE=10000
export HISTSIZE=500
# Don't put duplicate lines in the history
export HISTCONTROL=erasedups:ignoredups

# ----------------------
# Aliases
# ----------------------
# To temporarily bypass an alias, we preceed the command with a \
# EG: the ls command is aliased, but to use the normal ls command you would type \ls
alias l="ls -lh" # List files in current directory
alias ll="ls -al" # List all files in current directory in long list format
alias o="open ." # Open the current directory in Finder
alias cls='clear'

# Change directory aliases
alias home='cd ~'
alias dev='cd /c/dev'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Programs
alias c="code"

# ----------------------
# Git Aliases and functions
# ----------------------
alias gaa='git add .'
alias gcm='git commit -m'
alias gpsh='git push'
alias gpl='git pull'
alias gss='git status -s'
alias gs='git status --short'
# requires the 'gitui' utility to be installed
alias gui='gitui'

# Delete all branches that do not have a remote
function gdelete() {
	local branches=$(git branch --vv | grep ": gone" | awk '{print $1}')
	if [ -n "$branches" ]; then
		echo "Deleting branches: $branches"
		read -p "Are you sure you want to delete these branches? (y/n): " confirm
		if [[ $confirm == [yY] ]]; then
			echo "$branches" | xargs git branch -D
			echo "Branches deleted"
		else
			echo "Operation cancelled"
		fi
	else
		echo "No branches to delete"
	fi
}

# ----------------------
# Functions
# ----------------------
# Create directory and navigate to it
function mkcd()
{
	mkdir -p $1 && cd $1
}
# Remove a directory and all files
function rmd()
{
	local path=$1
	if [ -z "$path" ]; then
		echo "Usage: rmd <directory>"
		return 1
	fi

	printf "Are you sure you want to delete all of '$path' ? (y/n): "
	read confirm
	if [[ $confirm == [yY] ]]; then
		/bin/rm -rfv "$path"
		echo "'$path' has been deleted"
	else
		echo "Operation cancelled"
	fi
}

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# zprof # uncomment to profile startup time