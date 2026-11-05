#!/bin/sh
# install.sh — install ls.lua, its man page, and a tealdeer custom tldr page.
# Usage:
#   ./install.sh [install]     # default
#   ./install.sh uninstall
#
# Environment:
#   PREFIX   install root (default: $HOME/.local; use /usr/local for system-wide)
#   DESTDIR  staging root prepended to PREFIX (default: empty)
#   TEALDEER_CONFIG_DIR  tealdeer config directory (same meaning as tealdeer itself)

set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CMD=${1:-install}
NAME=ls.lua
MANPAGE=ls.lua.1
TLDR_SRC=$ROOT/tldr/ls.lua.md

if [ -z "${PREFIX+set}" ]; then
  if [ "$(id -u)" -eq 0 ]; then
    PREFIX=/usr/local
  else
    PREFIX=$HOME/.local
  fi
fi
DESTDIR=${DESTDIR:-}

BINDIR=${DESTDIR}${PREFIX}/bin
MANDIR=${DESTDIR}${PREFIX}/share/man/man1

die() { printf '%s\n' "$*" >&2; exit 1; }

need_src() {
  [ -f "$ROOT/$NAME" ] || die "missing $ROOT/$NAME"
  [ -f "$ROOT/$MANPAGE" ] || die "missing $ROOT/$MANPAGE"
  [ -f "$TLDR_SRC" ] || die "missing $TLDR_SRC"
}

install_file() {
  # install_file mode src dest
  mode=$1 src=$2 dest=$3
  dir=$(dirname -- "$dest")
  mkdir -p -- "$dir"
  cp -- "$src" "$dest"
  chmod "$mode" -- "$dest"
}

# --- tealdeer custom pages ---------------------------------------------------
# Docs: https://docs.tealdeer.org/latest/usage_custom_pages.html
# File name: <command>.page.md  (since tealdeer 1.7.0)
# Default dir (Linux): ${XDG_DATA_HOME:-$HOME/.local/share}/tealdeer/pages/
# Override via config.toml [directories] custom_pages_dir = "/abs/path"
# Config dir: $TEALDEER_CONFIG_DIR or ${XDG_CONFIG_HOME:-$HOME/.config}/tealdeer

is_tealdeer() {
  command -v tldr >/dev/null 2>&1 || return 1
  ver=$(tldr --version 2>/dev/null || true)
  case $ver in
    *[Tt]ealdeer*) return 0 ;;
  esac
  # Older builds may omit the name; --show-paths is tealdeer-specific.
  tldr --show-paths >/dev/null 2>&1
}

tealdeer_config_dir() {
  if [ -n "${TEALDEER_CONFIG_DIR:-}" ]; then
    printf '%s\n' "$TEALDEER_CONFIG_DIR"
  else
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/tealdeer"
  fi
}

tealdeer_custom_pages_dir() {
  # Prefer live path from the installed client.
  if command -v tldr >/dev/null 2>&1; then
    path=$(tldr --show-paths 2>/dev/null | sed -n 's/^Custom pages dir:[[:space:]]*//p' | head -n 1)
    if [ -n "$path" ]; then
      # Strip trailing " (OS convention)" / " (config file)" notes.
      path=$(printf '%s\n' "$path" | sed 's/[[:space:]]([^)]*)$//; s:/*$::')
      if [ -n "$path" ]; then
        printf '%s\n' "$path"
        return 0
      fi
    fi
  fi

  cfg=$(tealdeer_config_dir)/config.toml
  if [ -f "$cfg" ]; then
    # Match: custom_pages_dir = "/abs/path"  (optional spaces/quotes)
    path=$(sed -n 's/^[[:space:]]*custom_pages_dir[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg" | head -n 1)
    if [ -z "$path" ]; then
      path=$(sed -n "s/^[[:space:]]*custom_pages_dir[[:space:]]*=[[:space:]]*'\([^']*\)'.*/\1/p" "$cfg" | head -n 1)
    fi
    if [ -n "$path" ]; then
      printf '%s\n' "$path"
      return 0
    fi
  fi

  printf '%s\n' "${XDG_DATA_HOME:-$HOME/.local/share}/tealdeer/pages"
}

# tlrc has no custom-pages directory (only --render <file> and a full cache).
# tldr-python-client has --render and TLDR_PAGES_SOURCE_LOCATION file:// overrides,
# but no drop-in custom page slot that coexists with the upstream cache.
# tldr-node-client likewise has no local custom-pages dir.
# Detect them only so we can print a skip note.

is_tlrc() {
  command -v tldr >/dev/null 2>&1 || return 1
  ver=$(tldr --version 2>/dev/null || true)
  case $ver in
    *tlrc*) return 0 ;;
  esac
  # tlrc exposes --config-path / --gen-config; tealdeer does not.
  tldr --config-path >/dev/null 2>&1 && ! tldr --show-paths >/dev/null 2>&1
}

is_tldr_python() {
  command -v tldr >/dev/null 2>&1 || return 1
  # Python client's --version is typically "tldr <ver>" without tealdeer/tlrc,
  # and it supports --render as a long option listed in --help.
  helptxt=$(tldr --help 2>/dev/null || true)
  case $helptxt in
    *--render*|*--update_cache*) 
      is_tealdeer && return 1
      is_tlrc && return 1
      return 0
      ;;
  esac
  return 1
}

do_install() {
  need_src
  printf 'Installing %s -> %s/%s\n' "$NAME" "$BINDIR" "$NAME"
  install_file 755 "$ROOT/$NAME" "$BINDIR/$NAME"
  printf 'Installing man page -> %s/%s\n' "$MANDIR" "$MANPAGE"
  install_file 644 "$ROOT/$MANPAGE" "$MANDIR/$MANPAGE"

  # tldr custom pages live in the user's data dir, not under PREFIX.
  # Skip them when DESTDIR is set (packaging/staging).
  installed_tldr=0
  if [ -n "$DESTDIR" ]; then
    printf 'DESTDIR set; skipping tldr client page (user-local).\n'
  else
    if is_tealdeer; then
      pages=$(tealdeer_custom_pages_dir)
      dest=$pages/${NAME}.page.md
      printf 'Installing tealdeer custom page -> %s\n' "$dest"
      install_file 644 "$TLDR_SRC" "$dest"
      installed_tldr=1
      printf '  (run `tldr --update` once if the cache is empty, then: tldr %s)\n' "$NAME"
    fi

    if is_tlrc; then
      printf 'tlrc detected: no custom-pages directory; skipped.\n'
      printf '  Preview with: tldr --render %s\n' "$TLDR_SRC"
    fi

    if is_tldr_python; then
      printf 'tldr-python-client detected: no drop-in custom-pages slot; skipped.\n'
      printf '  Preview with: tldr --render %s\n' "$TLDR_SRC"
    fi

    if [ "$installed_tldr" -eq 0 ] && ! is_tlrc && ! is_tldr_python; then
      if command -v tldr >/dev/null 2>&1; then
        printf 'tldr client found at %s, but custom pages are unsupported or unrecognized; skipped.\n' "$(command -v tldr)"
        printf '  Page source remains at %s\n' "$TLDR_SRC"
      else
        printf 'No tldr client found; skipped tldr page install.\n'
        printf '  Install tealdeer, then re-run: ./install.sh\n'
        printf '  (tealdeer custom page path: %s/%s.page.md)\n' \
          "${XDG_DATA_HOME:-$HOME/.local/share}/tealdeer/pages" "$NAME"
      fi
    fi
  fi

  printf 'Done. Try: %s -a ;  man %s\n' "$BINDIR/$NAME" "$NAME"
}

do_uninstall() {
  rm -f -- "$BINDIR/$NAME"
  rm -f -- "$MANDIR/$MANPAGE"
  printf 'Removed %s and %s (if present)\n' "$BINDIR/$NAME" "$MANDIR/$MANPAGE"

  if is_tealdeer || [ -d "${XDG_DATA_HOME:-$HOME/.local/share}/tealdeer/pages" ]; then
    pages=$(tealdeer_custom_pages_dir)
    dest=$pages/${NAME}.page.md
    if [ -f "$dest" ]; then
      rm -f -- "$dest"
      printf 'Removed tealdeer custom page %s\n' "$dest"
    fi
  fi
  printf 'Done.\n'
}

case $CMD in
  install)   do_install ;;
  uninstall) do_uninstall ;;
  -h|--help|help)
    printf 'Usage: %s [install|uninstall]\n' "$0"
    printf '  PREFIX=%s  DESTDIR=%s\n' "$PREFIX" "${DESTDIR:-<empty>}"
    ;;
  *) die "unknown command: $CMD (use install or uninstall)" ;;
esac
