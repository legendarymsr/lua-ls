#!/usr/bin/env lua5.4
-- ls.lua: a tiny ls(1) clone in Lua 5.4 + luaposix
local dirent = require("posix.dirent")
local stat = require("posix.sys.stat")
local pwd = require("posix.pwd")
local grp = require("posix.grp")
local unistd = require("posix.unistd")

local opts = { all = false, long = false, one = false }
local paths = {}
for _, a in ipairs(arg) do
  if a:sub(1, 1) == "-" and #a > 1 then
    for c in a:sub(2):gmatch(".") do
      if c == "a" then opts.all = true
      elseif c == "l" then opts.long = true
      elseif c == "1" then opts.one = true
      else
        io.stderr:write("ls.lua: invalid option -- '" .. c .. "'\n")
        os.exit(2)
      end
    end
  else
    paths[#paths + 1] = a
  end
end
if #paths == 0 then paths[1] = "." end

local tty = unistd.isatty(1) == 1

local function modestr(m)
  local t = stat.S_ISDIR(m) ~= 0 and "d" or stat.S_ISLNK(m) ~= 0 and "l" or "-"
  local bits = { "r", "w", "x" }
  local s = t
  for i = 8, 0, -1 do
    s = s .. ((m & (1 << i)) ~= 0 and bits[(8 - i) % 3 + 1] or "-")
  end
  return s
end

local function color(name, st)
  if not tty or not st then return name end
  if stat.S_ISDIR(st.st_mode) ~= 0 then return "\27[1;34m" .. name .. "\27[0m" end
  if stat.S_ISLNK(st.st_mode) ~= 0 then return "\27[1;36m" .. name .. "\27[0m" end
  if st.st_mode & 73 ~= 0 then return "\27[1;32m" .. name .. "\27[0m" end
  return name
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
  local ok, names = pcall(function()
    local t = {}
    for name in dirent.files(dir) do
      if opts.all or name:sub(1, 1) ~= "." then t[#t + 1] = name end
    end
    return t
  end)
  if not ok then
    io.stderr:write("ls.lua: cannot open directory '" .. dir .. "': " .. (tostring(names):match("%((.-)%)") or tostring(names)) .. "\n")
    return false
  end
  table.sort(names)
  local rows = {}
  for _, name in ipairs(names) do
    local st = stat.lstat(dir .. "/" .. name)
    rows[#rows + 1] = { name = name, st = st }
  end
  if opts.long then
    for _, r in ipairs(rows) do
      local st = r.st
      local name = color(r.name, st)
      if stat.S_ISLNK(st.st_mode) ~= 0 then name = name .. " -> " .. (unistd.readlink(dir .. "/" .. r.name) or "?") end
      print(string.format("%s %2d %-8s %-8s %8d %s %s", modestr(st.st_mode), st.st_nlink,
        owner(st.st_uid), group(st.st_gid), st.st_size,
        os.date("%b %e %H:%M", st.st_mtime), name))
    end
  elseif opts.one or not tty then
    for _, r in ipairs(rows) do print(color(r.name, r.st)) end
  else
    local out = {}
    for _, r in ipairs(rows) do out[#out + 1] = color(r.name, r.st) end
    print(table.concat(out, "  "))
  end
  return true
end

local status = 0
for i, p in ipairs(paths) do
  if #paths > 1 then print((i > 1 and "\n" or "") .. p .. ":") end
  if not list(p) then status = 2 end
end
os.exit(status)
