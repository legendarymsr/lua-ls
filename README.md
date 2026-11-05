![STOP USING ELISP — Lua ls video thumbnail](thumbnail.png)

# lua-ls

A small `ls` clone written in Lua 5.4 with [luaposix](https://github.com/luaposix/luaposix).

This is a simple clone written for learning and the video guide. It's not meant to compete with GNU coreutils `ls` or BusyBox `ls`, which have far more options and are much more robust.

Supports `-a`, `-l` and `-1`, colors on a terminal, and symlink targets in `-l`.

## Usage

    sudo apt install lua5.4 lua-posix   # or: luarocks install luaposix
    ./ls.lua [-a] [-l] [-1] [dir]
    man ./ls.lua.1

## Install

    ./install.sh                 # PREFIX=$HOME/.local (or /usr/local if root)
    # PREFIX=/usr/local ./install.sh
    # DESTDIR=/tmp/stage PREFIX=/usr/local ./install.sh

Installs `ls.lua` to `$PREFIX/bin`, the man page to `$PREFIX/share/man/man1`,
and — when [tealdeer](https://github.com/tealdeer-rs/tealdeer) is on `PATH` and
`DESTDIR` is unset — a custom page so `tldr ls.lua` works
(`~/.local/share/tealdeer/pages/ls.lua.page.md` by default; respects
`TEALDEER_CONFIG_DIR` and `directories.custom_pages_dir`).

    ./install.sh uninstall

tlrc and the official Python/Node clients have no drop-in custom-pages slot;
use `tldr --render tldr/ls.lua.md` with those, or install tealdeer.

## Docs

- Man page: [`ls.lua.1`](ls.lua.1) — full options, colours, exit status, examples (`man ./ls.lua.1`)
- TLDR: [`tldr/ls.lua.md`](tldr/ls.lua.md) — short examples in [tldr-pages](https://tldr.sh) format

`steps/` holds the program at each stage of the video guide.

## Video

The video guide, which writes this in Neovim with lua-language-server and compares it to GNU and BusyBox `ls`, is attached to the release.

## License

GPL-3.0-or-later
