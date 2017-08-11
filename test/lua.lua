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
local dfs = {}

local stack1 = { root }
local stack2 = {}
while true do
  local n1 = #stack1
  local n2 = #stack2
  local node = stack1[n1]
  if not node then
    break
  end
  if node == stack2[n2] then
    stack1[n1] = nil
    stack2[n2] = nil
    id = id + 1
    node.id = id
    dfs[id] = node
    for i = 1, node.n do
      node[i].parent = node
    end
  else
    for i = node.n, 1, -1 do
      stack1[#stack1 + 1] = node[i]
    end
    stack2[n2 + 1] = node
  end
end

for i = 1, #dfs do
  local node = dfs[i]
  local parent_node = node.parent
  if parent_node then
    print(i, symbol_names[node[0]], parent_node.id)
  else
    print(i, symbol_names[node[0]])
  end
end


