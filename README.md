# dotfiles

Personal git aliases and zsh shortcuts, shared across machines and VSCode environments.

## Install

```sh
git clone <this-repo-url> ~/src/dotfiles
~/src/dotfiles/install.sh
```

Open a new terminal afterwards. The installer is safe to re-run.

What it changes:

- **`~/.gitconfig`**: adds an `[include]` pointing at `git/gitconfig`. Your existing settings and includes are left alone.
- **`~/.zshrc`**: adds a small block between `# >>> dotfiles >>>` and `# <<< dotfiles <<<` that sources `shell/git.sh`.

Both point at the files in the repo, so a `git pull` picks up changes with no reinstall. Keep the clone where it is; if you move it, re-run `install.sh`.

### Options

| Flag | Env var | Default | Purpose |
|---|---|---|---|
| `-b`, `--main-branch NAME` | `DOTFILES_MAIN_BRANCH` | `main` | Branch `gprm` rebases onto |
| `--zshrc PATH` | `DOTFILES_ZSHRC` | `${ZDOTDIR:-$HOME}/.zshrc` | zsh startup file to update |
| `-n`, `--dry-run` | | | Show what would change |
| `-u`, `--uninstall` | | | Remove everything install added |

Flags win over env vars. `--main-branch` is only written when given, so re-running without it keeps the current value.

## Shortcuts

| Shell | Git alias | Does |
|---|---|---|
| `gl` | `git lg` | Graph of the last 20 commits for your branch and its `origin/<branch>`. Pass extra args: `gl -50`, `gl -- src/` |
| `gla` | `git lga` | Same graph, all branches |
| `gls` | `git ls` | Last 10 commits, one line each, no graph |
| `gs` | `git st` | `git status -sb` |
| `gd` / `gds` | | `git diff` / `git diff --staged` |
| `gprm` | `git prm` | `git pull --rebase origin <main branch>` |
| `gpsu` | `git psu` | Push current branch and set upstream on `origin` |
| `gpf` | `git pf` | `git push --force-with-lease` |
| | `git amend` | Add staged changes to the last commit, same message |
| | `git undo` | Undo the last commit, keep its changes staged |

The git aliases work in any shell; the short names need zsh.

### Repos that use `master`

```sh
git config dotfiles.mainBranch master           # this repo only
git config --global dotfiles.mainBranch master  # everywhere (same as install.sh -b master)
```

## VSCode

The aliases live in your shell and git config, so VSCode uses them through its **integrated terminal**. VSCode's Source Control panel doesn't use them.

### 1. Make zsh the terminal shell

In `settings.json` (Cmd/Ctrl+Shift+P → *Preferences: Open User Settings (JSON)*):

```jsonc
{
  "terminal.integrated.defaultProfile.osx": "zsh",
  "terminal.integrated.defaultProfile.linux": "zsh"
}
```

zsh is already the default on macOS, but containers and remote Linux hosts often default to bash.

### 2. Local machine

Run the [install](#install) steps once. Every VSCode window on the machine picks it up. Terminals that were already open need to be closed and reopened (or `source ~/.zshrc`).

### 3. Remote-SSH

VSCode doesn't install dotfiles on SSH hosts. Clone the repo and run `install.sh` once on each host, just like on a local machine.

### 4. Dev Containers

The Dev Containers extension can clone this repo and run the installer in every container you open. Add to your **user** `settings.json`:

```jsonc
{
  "dotfiles.repository": "<github-user>/dotfiles",
  "dotfiles.targetPath": "~/dotfiles",
  "dotfiles.installCommand": "install.sh"
}
```

Rebuild the container (*Dev Containers: Rebuild Container*) to apply it. The container must have `git` and `zsh`.

### 5. GitHub Codespaces

In GitHub → **Settings → Codespaces → Dotfiles**, tick *Automatically install dotfiles* and select this repo. Codespaces runs `install.sh` from the repo root automatically. New codespaces get it; existing ones need a rebuild.

### Setting the main branch in remote environments

Dev Containers and Codespaces run `install.sh` with no arguments, so `gprm` uses `main`. For a repo that uses `master`, run this once inside it:

```sh
git config dotfiles.mainBranch master
```

## Uninstall

```sh
~/src/dotfiles/install.sh --uninstall
```
