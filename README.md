# dotfiles

Single source of truth for this system's configuration (Omarchy/Hyprland).
Live locations are symlinked into this repo so changes can be committed and
re-applied after OS or package updates.

## Layout

| Repo path                              | Live location                                  |
|----------------------------------------|------------------------------------------------|
| `hypr/` (dir link)                     | `~/.config/hypr/`                              |
| `omarchy/` (dir link)                  | `~/.config/omarchy/`                           |
| `ghostty/` (dir link)                  | `~/.config/ghostty/`                           |
| `git/` (dir link)                      | `~/.config/git/`                               |
| `mise/` (dir link)                     | `~/.config/mise/`                              |
| `nvim/` (dir link)                     | `~/.config/nvim/`                              |
| `share-picker/config.yaml` (file link) | `~/.config/hyprland-preview-share-picker/`     |
| `starship.toml` (file link)            | `~/.config/starship.toml`                      |
| `aether/*` (file links)                | `~/.config/aether/` (selected files only)      |
| `tmux/tmux.conf` (file link)           | `~/.config/tmux/tmux.conf`                     |

Links are declared in `links.tsv`; whole directories are linked as a single
directory symlink, mixed dirs use per-file links.

## Usage

```
./install.sh              # apply: adopt files into the repo if missing, back up
                          # anything in the way, then (re)create all symlinks
./install.sh --check      # verify every link; exits non-zero on any drift
./install.sh --dry-run    # preview without changing anything
./install.sh --link hypr  # apply only entries matching "hypr"
```

Run `./install.sh --check` after `omarchy update` or `omarchy refresh ...`:
those commands sometimes replace a symlink with a plain file, and this will
spot it and `./install.sh` will restore the link.

## Branding

Two locally-branded assets live in the repo and are re-applied from
`./install.sh` because `omarchy update` restores the stock Omarchy assets:

- `omarchy/plugins/tomikkdyne.menu/assets/menu-logo.png` — the menu/launcher
  button in the QuickShell bar (drives the leftmost bar widget via
  `tomikkdyne.menu`, a clone of `omarchy.menu`). The bar hot-reloads on save.
- `omarchy/branding/boot-logo.png` — the boot splash (Plymouth) and login
  greeter (SDDM) logo. Replace it with your own image, then re-apply.
- `omarchy/branding/boot-logo.colors` — two hex colors, one per line: the
  splash background and the text/foreground color (no `#`).

Apply just the boot logo (prompts for `sudo`; deploys to both Plymouth and
SDDM and rebuilds the initramfs):

```
./install.sh --link boot-logo
```

`--check` and `--dry-run` also report the boot logo state.

## Hyprland

Hyprland config is Lua-only (`hyprland.lua`); the legacy `.conf` API has been
retired. Personal settings live in:

- `hypr/input.lua` — keyboard/mouse/touchpad, ghostty scroll speed
- `hypr/looknfeel.lua` — borders, opacity, rounding
- `hypr/monitors.lua` — monitors and workspace assignment
- `hypr/bindings.lua` — keybinding overrides vs. Omarchy defaults
- `hypr/autostart.lua` — window rules and autostart apps

`hyprsunset.conf`, `xdph.conf`, `hypridle.conf`, and `hyprlock.conf` are read
by separate daemons, not Hyprland.

Runtime artifacts (upgrade `.bak` files, auto-generated `shaders/`, aether's
generated theme) live on disk but are ignored by git via `.gitignore`.