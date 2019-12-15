# System-wide .profile file for the Bourne shell (sh(1))

# Set prompt to user@host:pwd$
export PS1="\u@\h:\w\\\$ "

# Set text processors
export EDITOR=vi
export PAGER=less

# Set default umask
umask 022

# Ask before rm *
set rmstar

# Command aliases
alias cls=clear
alias ll="ls -alh"
alias more=${PAGER}

# Set bash specific options
if [ "${BASH}" ]; then
  # Dynamic window resizing
  shopt -s checkwinsize

  # Turn on parallel history
  shopt -s histappend
  PROMPT_COMMAND="history -a"
  HISTSIZE=1000
  HISTFILESIZE=100000
  HISTCONTROL=ignoreboth:erasedups
  HISTIGNORE='exit'
fi
