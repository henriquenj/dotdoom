# Spacemacs-inspired bindings for Doom Emacs

This is my personal Doom Emacs configuration (`$DOOMDIR`) using Spacemacs-style
keybinds. This is mostly due to years of deeply ingrained muscle memory.

## Install

```bash
git clone --recurse-submodules https://github.com/doomemacs/core ~/.emacs.d
git clone https://github.com/henriquenj/dotdoom ~/.doom.d
~/.emacs.d/bin/doom install
```

## Pinned Doom revision

`doom-pin` records the Doom revision this config is known to work with. Work
machines follow that pin rather than upstream `master`, so an untested commit
never lands on a machine I depend on.

One SHA is enough: Doom's core commit records the exact `sources/doom+`
(modules) revision as a submodule gitlink, and those modules pin their own
packages. Checking out the pin therefore reproduces the whole tree.

### Deploy a pinned revision (work machines)

```bash
git -C ~/.doom.d pull
~/.doom.d/bin/doom-deploy
```

Fetches, checks out the pin, updates the modules submodule, then runs
`doom sync -u` to move packages onto the pins recorded at that revision.
Refuses to run if `~/.emacs.d` has uncommitted changes.

The checkout is deliberately detached, leaving `master` untouched — otherwise
`git status` would report "behind origin/master" and invite a `git pull` that
silently breaks the pin.

Do not run `doom upgrade` on these machines. It is hardcoded to pull upstream
`master` and would overshoot the pin.

### Promote a new revision (test machine)

```bash
~/.emacs.d/bin/doom upgrade
# ...use Emacs for a while...
~/.doom.d/bin/doom-promote
git -C ~/.doom.d commit doom-pin -m 'Pin Doom to <version>'
```

`doom-promote` writes the currently-installed revision into `doom-pin` and
stages nothing, so the diff is reviewed before it becomes the deployed
revision. Rolling back is `git revert` on the pin commit, then a redeploy.

### If a sync is interrupted

Re-run it as `~/.emacs.d/bin/doom sync -b`. An aborted sync can leave packages
whose repos were updated but whose builds were not, which surfaces later as
void-function errors at runtime; `-b` rebuilds unconditionally.
