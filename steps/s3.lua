#!/usr/bin/env lua5.4
-- ls.lua: a tiny ls(1) clone in Lua 5.4 + luaposix
local dirent = require("posix.dirent")
local stat = require("posix.sys.stat")
local pwd = require("posix.pwd")
local grp = require("posix.grp")

local opts = { all = false, long = false, one = false }
local paths = {}
for _, a in ipairs(arg) do
  if a:sub(1, 1) == "-" and #a > 1 then
    for c in a:sub(2):gmatch(".") do
      if c == "a" then opts.all = true
      elseif c == "l" then opts.long = true
      elseif c == "1" then opts.one = true
      end
    end
  else
    paths[#paths + 1] = a
  end
end
if #paths == 0 then paths[1] = "." end

local function modestr(m)
  local s = stat.S_ISDIR(m) ~= 0 and "d" or stat.S_ISLNK(m) ~= 0 and "l" or "-"
  local bits = { "r", "w", "x" }
  for i = 8, 0, -1 do
    s = s .. ((m & (1 << i)) ~= 0 and bits[(8 - i) % 3 + 1] or "-")
  end
  return s
end

local function owner(uid)
  local p = pwd.getpwuid(uid)
  return p and p.pw_name or tostring(uid)
end

local function group(gid)
  local g = grp.getgrgid(gid)
  return g and g.gr_name or tostring(gid)
end

local function list(dir)
  local names = {}
  for name in dirent.files(dir) do
    if opts.all or name:sub(1, 1) ~= "." then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  if opts.long then
    for _, name in ipairs(names) do
      local st = stat.lstat(dir .. "/" .. name)
      print(string.format("%s %2d %-8s %-8s %8d %s %s", modestr(st.st_mode), st.st_nlink,
        owner(st.st_uid), group(st.st_gid), st.st_size,
        os.date("%b %e %H:%M", st.st_mtime), name))
    end
  elseif opts.one then
    for _, name in ipairs(names) do print(name) end
  else
    print(table.concat(names, "  "))
  end
end

for _, p in ipairs(paths) do
  list(p)
end
