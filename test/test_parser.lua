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

local dumper = require "dromozoa.commons.dumper"
local builder = require "dromozoa.parser.builder"
local parser = require "dromozoa.parser.parser"

local _ = builder()
local P = builder.pattern
local R = builder.range
local S = builder.set

_:lexer()
  :_(S" \t\n\v\f\r"^"+") :skip()
  :_(R"09"^"+") :as "id"
  :_ "+"
  :_ "*"
  :_ "("
  :_ ")"

--_ "E"
--  :_ "E" "+" "T"
--  :_ "T"
--
--_ "T"
--  :_ "T" "*" "F"
--  :_ "F"
--
--_ "F"
--  :_ "(" "E" ")"
--  :_ "id"

_ :left "+"
  :left "*"

_"E"
  :_ "E" "+" "E"
  :_ "E" "*" "E"
  :_ "(" "E" ")"
  :_ "id"

local scanner, grammar = _:build()
print(dumper.encode(grammar, { pretty = true, stable = true }))

local data = grammar:lr1_construct_table(grammar:lalr1_items())
print(dumper.encode(data, { stable = true }))

local symbol_names = _.symbol_names
local _ = _.symbol_table

local p = parser(data)
-- assert(p(_["("]))
assert(p(_["id"], { value = 17 }))
assert(p(_["+"]))
assert(p(_["id"], { value = 23 }))
-- assert(p(_[")"]))
assert(p(_["*"]))
assert(p(_["id"], { value = 37 }))
local tree = assert(p(1))
-- print(dumper.encode(tree, { pretty = true, stable = true }))

local out = assert(io.open("test.dot", "w"))
out:write([[
digraph g {
graph [rankdir=TB];
node [shape=box];
]])

tree.depth = 0
tree.id = 1
local id = 1
local stack = { tree }
while true do
  local n = #stack
  local node = stack[n]
  if node then
    stack[n] = nil
    local data = node.data
    local value = ""
    if data then
      value = " / " .. data.value
    end
    -- io.write(("  "):rep(node.depth), symbol_names[node[1]], value, "\n")
    out:write(([[
%d [label=<%s%s>];
]]):format(node.id, symbol_names[node[1]], value))
    for i = 2, node.n do
      id = id + 1
      node[i].id = id
      out:write(([[
%d -> %d;
]]):format(node.id, id))
    end
    for i = node.n, 2, -1 do
      node[i].depth = node.depth + 1
      stack[#stack + 1] = node[i]
    end
  else
    break
  end
end

out:write("}\n")

out:close()
