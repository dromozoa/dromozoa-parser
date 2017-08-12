-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-parser.
--
-- dromozoa-parser is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-parser is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-parser.  If not, see <http://www.gnu.org/licenses/>.

local lua53_lexer = require "dromozoa.parser.lexers.lua53_lexer"
local lua53_parser = require "dromozoa.parser.parsers.lua53_parser"

local file = ...
local handle = assert(io.open(file))
local source = handle:read("*a")
handle:close()

local lexer = lua53_lexer()
local parser = lua53_parser()

local symbol_names = parser.symbol_names
local terminal_nodes = assert(lexer(source, file))
local root = assert(parser(terminal_nodes, source, file))
parser:write_graphviz("test.dot", root)

local max_terminal_symbol = parser.max_terminal_symbol
local symbol_names = parser.symbol_names
local symbol_table = parser.symbol_table

local id = 0
local nodes = {}
local dfs_events = {}
local dfs_nodes = {}

local stack1 = { root }
local stack2 = {}
while true do
  local n1 = #stack1
  local n2 = #stack2
  local u = stack1[n1]
  if not u then
    break
  end
  if u == stack2[n2] then
    stack1[n1] = nil
    stack2[n2] = nil
    local m = #dfs_events + 1
    dfs_events[m] = 2 -- finish
    dfs_nodes[m] = u
  else
    id = id + 1
    u.id = id
    nodes[id] = u
    local m = #dfs_events + 1
    dfs_events[m] = 1 -- discover
    dfs_nodes[m] = u
    local n = u.n
    for i = 1, n do
      local v = u[i]
      v.parent = u
    end
    for i = n, 1, -1 do
      local v = u[i]
      stack1[#stack1 + 1] = v
    end
    stack2[n2 + 1] = u
  end
end

local depth = 0
for i = 1, #dfs_events do
  local event = dfs_events[i]
  local u = dfs_nodes[i]

  if event == 2 then
    depth = depth - 1
  end
  -- io.write(("  "):rep(depth), u.id, " ", symbol_names[u[0]], "\n")
  if event == 1 then
    io.write(("  "):rep(depth), u.id, " ", symbol_names[u[0]], "\n")
    depth = depth + 1
  end
end
