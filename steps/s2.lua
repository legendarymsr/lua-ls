#!/usr/bin/env lua5.4
-- ls.lua: a tiny ls(1) clone in Lua 5.4 + luaposix
local dirent = require("posix.dirent")

local opts = { all = false, one = false }
local paths = {}
for _, a in ipairs(arg) do
  if a:sub(1, 1) == "-" and #a > 1 then
    for c in a:sub(2):gmatch(".") do
      if c == "a" then opts.all = true
      elseif c == "1" then opts.one = true
      end
    end
  else
    paths[#paths + 1] = a
  end
end
if #paths == 0 then paths[1] = "." end

local function list(dir)
  local names = {}
  for name in dirent.files(dir) do
    if opts.all or name:sub(1, 1) ~= "." then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  if opts.one then
    for _, name in ipairs(names) do print(name) end
  else
    print(table.concat(names, "  "))
  end
end

for _, p in ipairs(paths) do
  list(p)
end
