#!/usr/bin/env bash
# Install (or uninstall) these dotfiles for the current user.
#
# Safe to re-run: every step checks what is already there before changing it.
# Files are referenced in place, so keep the repo where you cloned it
# (re-run install.sh if you move it).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_INCLUDE="$DOTFILES_DIR/git/gitconfig"
SHELL_FILES=("$DOTFILES_DIR/shell/git.sh")

BLOCK_START="# >>> dotfiles >>>"
BLOCK_END="# <<< dotfiles <<<"

# Settings, overridable by environment variable or flag (flags win).
MAIN_BRANCH="${DOTFILES_MAIN_BRANCH:-}"
ZSHRC="${DOTFILES_ZSHRC:-${ZDOTDIR:-$HOME}/.zshrc}"
ACTION=install
DRY_RUN=0

usage() {
	cat <<EOF
Usage: ./install.sh [options]

Options:
  -b, --main-branch NAME  Branch that 'gprm' rebases onto (default: main).
                          Only written when given, so re-runs keep the
                          existing value. Env: DOTFILES_MAIN_BRANCH
      --zshrc PATH        zsh startup file to update
                          (default: \${ZDOTDIR:-\$HOME}/.zshrc). Env: DOTFILES_ZSHRC
  -n, --dry-run           Print what would change without changing anything.
  -u, --uninstall         Remove everything install.sh added.
  -h, --help              Show this help.

Examples:
  ./install.sh
  ./install.sh --main-branch master
  DOTFILES_MAIN_BRANCH=master ./install.sh
EOF
}

while [ $# -gt 0 ]; do
	case "$1" in
		-b|--main-branch) MAIN_BRANCH="${2:?--main-branch needs a value}"; shift 2 ;;
		--main-branch=*)  MAIN_BRANCH="${1#*=}"; shift ;;
		--zshrc)          ZSHRC="${2:?--zshrc needs a value}"; shift 2 ;;
		--zshrc=*)        ZSHRC="${1#*=}"; shift ;;
		-n|--dry-run)     DRY_RUN=1; shift ;;
		-u|--uninstall)   ACTION=uninstall; shift ;;
		-h|--help)        usage; exit 0 ;;
		*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
	esac
done

log()  { printf '  %s\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then log "[dry-run] $*"; else "$@"; fi; }

command -v git >/dev/null || { echo "git is required but not installed." >&2; exit 1; }
command -v zsh >/dev/null || echo "warning: zsh not found; shell aliases will only load once zsh is installed." >&2

# --- git ---------------------------------------------------------------------

git_include_present() {
	git config --global --get-all include.path 2>/dev/null | grep -qxF "$GIT_INCLUDE"
}

install_git() {
	echo "git (~/.gitconfig):"
	if git_include_present; then
		log "include already present: $GIT_INCLUDE"
	else
		# --add so any includes you already have are left alone.
		run git config --global --add include.path "$GIT_INCLUDE"
		[ "$DRY_RUN" = 1 ] || log "added include: $GIT_INCLUDE"
	fi

	if [ -n "$MAIN_BRANCH" ]; then
		run git config --global dotfiles.mainBranch "$MAIN_BRANCH"
		log "dotfiles.mainBranch = $MAIN_BRANCH"
	else
		log "dotfiles.mainBranch = $(git config --global dotfiles.mainBranch || echo 'main (default)')"
	fi
}

uninstall_git() {
	echo "git (~/.gitconfig):"
	if git_include_present; then
		run git config --global --fixed-value --unset-all include.path "$GIT_INCLUDE"
		log "removed include: $GIT_INCLUDE"
	else
		log "include not present"
	fi
	if git config --global dotfiles.mainBranch >/dev/null; then
		run git config --global --unset dotfiles.mainBranch
		log "removed dotfiles.mainBranch"
	fi
}

# --- zsh ---------------------------------------------------------------------

# Print $ZSHRC without our managed block.
zshrc_without_block() {
	[ -f "$ZSHRC" ] || return 0
	awk -v s="$BLOCK_START" -v e="$BLOCK_END" '
		$0 == s { skip = 1; next }
		$0 == e { skip = 0; next }
		!skip
	' "$ZSHRC"
}

# Replace $ZSHRC's contents with stdin. Writes through symlinks, so a zshrc
# that is itself a link into another dotfiles repo stays a link.
write_zshrc() {
	local tmp
	tmp="$(mktemp)"
	cat > "$tmp"
	if [ "$DRY_RUN" = 1 ]; then
		log "[dry-run] would write $ZSHRC:"
		diff -u "$ZSHRC" "$tmp" 2>/dev/null | sed 's/^/    /' || true
	else
		cat "$tmp" > "$ZSHRC"
	fi
	rm -f "$tmp"
}

install_zsh() {
	echo "zsh ($ZSHRC):"
	{
		zshrc_without_block
		echo "$BLOCK_START"
		echo "# Managed by $DOTFILES_DIR/install.sh; edits here are overwritten."
		for f in "${SHELL_FILES[@]}"; do
			echo "[ -f \"$f\" ] && source \"$f\""
		done
		echo "$BLOCK_END"
	} | write_zshrc
	log "sources: ${SHELL_FILES[*]}"
}

uninstall_zsh() {
	echo "zsh ($ZSHRC):"
	if [ -f "$ZSHRC" ] && grep -qxF "$BLOCK_START" "$ZSHRC"; then
		zshrc_without_block | write_zshrc
		log "removed dotfiles block"
	else
		log "no dotfiles block found"
	fi
}

# -----------------------------------------------------------------------------

"${ACTION}_git"
"${ACTION}_zsh"

[ "$DRY_RUN" = 1 ] || echo "Done. Open a new terminal (or run: source $ZSHRC)."
