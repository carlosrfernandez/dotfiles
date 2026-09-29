# Short shell aliases for the git aliases in ../git/gitconfig.
# install.sh sources this from ~/.zshrc.

alias gl='git lg'
alias gla='git lga'
alias gls='git ls'
alias gs='git st'
alias gd='git diff'
alias gds='git diff --staged'
alias gprm='git prm'
alias gpsu='git psu'
alias gpf='git pf'
alias gamend='git amend'
alias gwl='git wl'

# Create the worktree, then cd into it.
gwcm() {
	local dir
	dir=$(git wcm "$@") && cd "$dir"
}

# Remove the worktree; if we were inside it, cd to the main checkout.
gwrm() {
	local main
	main=$(git wrm "$@") || return
	[ -d "$PWD" ] || cd "$main"
}
alias gwp='git wp'
