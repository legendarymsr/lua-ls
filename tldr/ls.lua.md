# ls.lua

> List directory contents (tiny ls clone in Lua 5.4 + luaposix).
> More information: <https://github.com/legendarymsr/lua-ls>.

- List files and directories in the current directory:

`ls.lua`

- List including hidden entries (names starting with `.`):

`ls.lua -a`

- List in long format (mode, links, owner, group, size, mtime, name):

`ls.lua -l`

- List one entry per line:

`ls.lua -1`

- List a specific directory in long format, including hidden entries:

`ls.lua -al {{path/to/directory}}`

- List several directories (prints a `DIR:` header for each):

`ls.lua {{path/to/dir1}} {{path/to/dir2}}`

- Write a plain, uncoloured one-per-line listing to a file:

`ls.lua -1 {{path/to/directory}} > {{names.txt}}`
