# Nvim

LazyVim-based Neovim setup with support for multiple config flavors.

## Layout

This folder supports multiple Neovim flavors. The current default flavor is:

```bash
lazyNvim
```

Real config files live at:

```bash
Nvim/lazyNvim
```

The installed config is a symlink:

```bash
~/.config/nvim -> <repo>/Nvim/lazyNvim
```

The repo folder can be named anything and live anywhere. Install scripts resolve paths relative to themselves.

## Install

From this folder:

```bash
./install.sh
```

Or from the repo root:

```bash
./Nvim/install.sh
```

To install a specific flavor:

```bash
./Nvim/install.sh lazyNvim
```

To remove old Neovim runtime/cache/state folders instead of backing them up:

```bash
./Nvim/install.sh lazyNvim --force-clean
```

By default, the installer backs up existing Neovim runtime data:

```bash
~/.local/share/nvim
~/.local/state/nvim
~/.cache/nvim
```

## Uninstall

```bash
./Nvim/uninstall.sh
```

This removes only the `~/.config/nvim` symlink if it points into this repo. It does not delete the config files in this repo.

## Health Check

Start Neovim:

```bash
nvim
```

Inside Neovim:

```vim
:LazyHealth
```

## Based on LazyVim Starter

The initial `lazyNvim` config comes from:

```bash
https://github.com/LazyVim/starter
```

The starter `.git` directory is removed so this Tools repo owns the config.

## Runtime Data

Neovim and LazyVim create machine-local runtime data under:

```bash
~/.local/share/nvim
~/.local/state/nvim
~/.cache/nvim
```

These are not tracked in this repo.
