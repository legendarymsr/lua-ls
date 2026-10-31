#!/usr/bin/env lua5.4
-- ls.lua: a tiny ls(1) clone in Lua 5.4 + luaposix
local dirent = require("posix.dirent")

local dir = arg[1] or "."
for name in dirent.files(dir) do
  print(name)
end
