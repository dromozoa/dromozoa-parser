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

local regexp_lexer = require "dromozoa.parser.lexers.regexp_lexer"
local regexp_parser = require "dromozoa.parser.parsers.regexp_parser"
local driver = require "dromozoa.parser.driver"

local source = arg[1] or [[\/\*.*?\*\/]]
local parser = regexp_parser()
local root = driver(regexp_lexer(), parser)(source)

local symbol_table = parser.symbol_table
local max_terminal_symbol = parser.max_terminal_symbol

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
    local symbol = node[0]
    if symbol == symbol_table.CharacterEscape then
      local a = node[1]
      node.value = a.value
    elseif symbol == symbol_table.ClassEscape then
      local a = node[1]
      if a[0] == symbol_table.CharacterClassEscape then
        error("not impl")
      else
        node.value = a.value
      end
    elseif symbol == symbol_table.ClassAtomNoDash then
      local a = node[1]
      node.value = a.value
    elseif symbol == symbol_table.ClassAtom then
      local a = node[1]
      node.value = a.value
    end
    if node.rs then
      print(("%s %q"):format(parser.symbol_names[symbol], node.rs:sub(node.ri, node.rj)))
    else
      print(("%s"):format(parser.symbol_names[symbol]))
    end
  else
    local n = node.n
    for i = n, 1, -1 do
      if node[i][0] > max_terminal_symbol then
        stack1[#stack1 + 1] = node[i]
      end
    end
    stack2[n2 + 1] = node
  end
end

parser:write_graphviz("test.dot", root)
