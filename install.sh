#!/usr/bin/env bash
# Dotfiles installer: manages symlinks from the live system into this repo.
#
# Links are declared in links.tsv, one per line:
#   <target relative to $HOME><TAB><path relative to repo root>
#
# Usage:
#   install.sh            Apply: adopt values into the repo if missing, back
#                         up any real files in the way, then create/fix links.
#                         Also re-applies the Plymouth + SDDM boot logo from
#                         omarchy/branding/boot-logo.{png,colors} via
#                         `omarchy plymouth set` (prompts for sudo).
#   install.sh --check    Verify every link; exit non-zero on any drift.
#                         Run this after omarchy update/refresh to spot links
#                         that a package upgrade replaced with real files, and
#                         to catch a stock boot logo that an update redeployed.
#   install.sh --dry-run  Print what apply WOULD do without changing anything.
#   install.sh --link <substr>  Restrict any mode to entries whose repo path
#                               or target contains <substr>. Applies to the
#                               boot-logo step too (e.g. --link boot-logo).

set -u

REPO_ROOT="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
MANIFEST="$REPO_ROOT/links.tsv"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="$REPO_ROOT/backup/$TIMESTAMP"

ACTION="${1:-apply}"
FILTER="${2:-}"

# git only stores the executable bit; restore stricter modes after (re)linking.
RESTRICTED_MODES=(
  "omarchy/shell.json"
)

# Boot/login branding. `install.sh` re-applies the custom Plymouth + SDDM
# logo with `omarchy plymouth set` because `omarchy update` redeploys the
# stock assets. Colors: first non-comment line = bg hex, second = text hex.
BRANDING_DIR="$REPO_ROOT/omarchy/branding"
BOOT_LOGO="$BRANDING_DIR/boot-logo.png"
BOOT_COLORS="$BRANDING_DIR/boot-logo.colors"

plymouth_filtered() { # honors --link <substr> like the manifest links do
  [ -z "$FILTER" ] || printf '%s%s' "$BOOT_LOGO" "$BRANDING_DIR" | grep -qF "$FILTER"
}

plymouth_colors() { # prints "bg_hex text_hex" from boot-logo.colors (strips comments)
  local bg="" text="" line
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [ -z "$line" ] && continue
    if [ -z "$bg" ]; then bg="$line"; else text="$line"; break; fi
  done < "$BOOT_COLORS"
  [ -n "$bg" ] && [ -n "$text" ] && printf '%s %s\n' "$bg" "$text"
}

plymouth_needs_apply() { # 0=needs re-apply, 1=already applied / cannot (missing)
  [ -f "$BOOT_LOGO" ] || return 1
  local installed="/usr/share/plymouth/themes/omarchy/logo.png" mine cur
  [ -f "$installed" ] || return 0
  mine="$(md5sum "$BOOT_LOGO" | cut -d' ' -f1)"
  cur="$(md5sum "$installed" | cut -d' ' -f1)"
  [ "$mine" = "$cur" ] && return 1
  return 0
}

plymouth_state() {
  if [ ! -f "$BOOT_LOGO" ]; then
    echo "MISSING   $BOOT_LOGO (add omarchy/branding/boot-logo.png)"
  elif [ ! -f "$BOOT_COLORS" ]; then
    echo "MISSING   $BOOT_COLORS"
  elif plymouth_needs_apply; then
    echo "OUTDATED  plymouth/sddm logo"
  else
    echo "OK        plymouth/sddm logo"
  fi
}

plymouth_apply() {
  if ! plymouth_filtered; then return 0; fi
  if [ ! -f "$BOOT_LOGO" ]; then
    warn "no $BOOT_LOGO; skipping boot logo (add one to customize Plymouth/SDDM)"
    return 0
  fi
  if [ ! -f "$BOOT_COLORS" ]; then
    err "missing $BOOT_COLORS; cannot deploy boot logo"
    return 1
  fi
  local colors
  colors="$(plymouth_colors)"
  if ! printf '%s' "$colors" | grep -qE '^[0-9a-fA-F]{6} [0-9a-fA-F]{6}$'; then
    err "boot-logo.colors must hold two 6-digit hex colors (bg, text); got: $colors"
    return 1
  fi
  if ! plymouth_needs_apply; then
    ok "plymouth/sddm logo already current"
    return 0
  fi
  # shellcheck disable=SC2086
  set -- $colors
  log "deploying boot logo via: omarchy plymouth set '$1' '$2' boot-logo.png"
  if omarchy plymouth set "$1" "$2" "$BOOT_LOGO"; then
    ok "boot logo deployed (Plymouth + SDDM)"
  else
    err "omarchy plymouth set failed"
    return 1
  fi
}

log()  { printf '\033[36m[dotfiles]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[dotfiles]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[32m[dotfiles]\033[0m %s\n' "$*"; }
err()  { printf '\033[31m[dotfiles]\033[0m %s\n' "$*" >&2; }

entries() {
  while IFS=$'\t' read -r rel repo; do
    [ -z "${rel:-}" ] && continue
    case "$rel" in \#*|'') continue ;; esac
    printf '%s\t%s\n' "$rel" "$repo"
  done < "$MANIFEST"
}

repo_empty() { # is a repo path present and, if a dir, empty?
  local repo="$1"
  [ ! -e "$repo" ] && return 0
  if [ -d "$repo" ] && [ -z "$(find "$repo" -mindepth 1 -print -quit)" ]; then
    return 0
  fi
  return 1
}

target_is_symlink_to() {
  local target="$1" repo="$2"
  [ -L "$target" ] && [ "$(realpath "$target")" = "$repo" ]
}

restore_modes() {
  for f in "${RESTRICTED_MODES[@]}"; do
    local p="$REPO_ROOT/$f"
    if [ -e "$p" ]; then
      chmod 600 "$p"
    fi
  done
}

apply_link() {
  local rel="$1" repo="$2"
  local target="$HOME/$rel" rp="$REPO_ROOT/$repo"
  local was_dir=0

  log "link: $rel  ->  $repo"

  if target_is_symlink_to "$target" "$rp"; then
    ok "  already linked correctly"
    return 0
  fi

  if [ -L "$target" ]; then
    warn "  symlink points somewhere else; replacing"
    rm -f "$target"
  fi

  if [ -e "$target" ]; then
    if repo_empty "$rp"; then
      log "  adopting existing content into repo"
      if [ -d "$target" ]; then
        mkdir -p "$rp"
        cp -a "$target/." "$rp/"
        rm -rf "$target"
      else
        mkdir -p "$(dirname "$rp")"
        cp -a "$target" "$rp"
        rm -f "$target"
      fi
    else
      mkdir -p "$BACKUP_DIR"
      log "  backing up existing $( [ -d "$target" ] && echo dir || echo file ) to backup/$TIMESTAMP"
      if [ -d "$target" ]; then
        mv "$target" "$BACKUP_DIR/$(basename "$target")"
      else
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
        mv "$target" "$BACKUP_DIR/$rel"
      fi
    fi
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$rp" "$target"
  ok "  linked"
}

evaluate() {
  local rel="$1" repo="$2"
  local target="$HOME/$rel" rp="$REPO_ROOT/$repo"

  if target_is_symlink_to "$target" "$rp"; then
    echo "OK        $rel"
  elif [ -L "$target" ]; then
    echo "MISMATCH  $rel  (-> $(readlink "$target"), want $rp)"
  elif [ -e "$target" ]; then
    [ -d "$target" ] && k=dir || k=file
    echo "UNLINKED  $rel  (real $k exists)"
  else
    echo "MISSING   $rel"
  fi
}

do_check() {
  local problems=0 rel repo
  while IFS=$'\t' read -r rel repo; do
    if [ -n "${FILTER:-}" ] && ! printf '%s%s' "$rel" "$repo" | grep -qF "$FILTER"; then
      continue
    fi
    local s
    s="$(evaluate "$rel" "$repo")"
    printf '%s\n' "$s"
    case "$s" in MISSING*|MISMATCH*|UNLINKED*) problems=$((problems+1)) ;; esac
  done < <(entries)
  if plymouth_filtered; then
    local p
    p="$(plymouth_state)"
    printf '%s\n' "$p"
    case "$p" in MISSING*|OUTDATED*) problems=$((problems+1)) ;; esac
  fi
  if [ "$problems" -gt 0 ]; then
    err "$problems link(s) need attention. Re-run: install.sh"
    return 1
  fi
  ok "all links are correct"
}

do_apply() {
  local matched=0 rel repo
  while IFS=$'\t' read -r rel repo; do
    if [ -n "$FILTER" ] && ! printf '%s%s' "$rel" "$repo" | grep -qF "$FILTER"; then
      continue
    fi
    matched=1
    apply_link "$rel" "$repo"
  done < <(entries)

  if [ "$matched" -eq 0 ] && ! plymouth_filtered; then
    err "no manifest entry matched filter: ${FILTER:-}"
    return 1
  fi
  restore_modes
  plymouth_apply
}

do_dryrun() {
  local rel repo
  while IFS=$'\t' read -r rel repo; do
    if [ -n "$FILTER" ] && ! printf '%s%s' "$rel" "$repo" | grep -qF "$FILTER"; then
      continue
    fi
    echo "$(evaluate "$rel" "$repo")"
  done < <(entries)
  if plymouth_filtered; then
    plymouth_state
  fi
}

case "$ACTION" in
  --check)         do_check ;;
  --dry-run)       do_dryrun ;;
  --link)          ACTION=apply; FILTER="${2:-}"; do_apply ;;
  apply|"")        do_apply ;;
  *)               err "unknown action: $ACTION (use apply, --check, --dry-run, --link <substr>)"; exit 2 ;;
esac