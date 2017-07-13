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
local driver = require "dromozoa.parser.driver"
local writer = require "dromozoa.parser.writer"

local _ = builder()
local P = builder.pattern
local R = builder.range
local S = builder.set

_:lexer()
  :_ "="
  :_ "*"
  :_ "id"

_"S"
  :_ "L" "=" "R"
  :_ "R"
_"L"
  :_ "*" "R"
  :_ "id"
_"R"
  :_ "L"

local lexer, grammar = _:build()
local writer = writer(_.symbol_names, grammar.productions, grammar.max_teminal_symbol)

-- print(dumper.encode(scanner, { pretty = true, stable = true }))
-- print(dumper.encode(grammar, { pretty = true, stable = true }))
-- print(dumper.encode(writer, { pretty = true, stable = true }))

local set_of_items, transitions = grammar:lr0_items()
local set_of_kernel_items, map_of_kernel_items = grammar:lalr1_kernels(set_of_items, transitions)
-- print(dumper.encode(set_of_items, { pretty = true, stable = true }))
-- for from, to in pairs(transitions) do
--   print(dumper.encode({ from = from, to = to }, { stable = true }))
-- end
writer:write_set_of_items(io.stdout, set_of_kernel_items)

local map = {}
-- for from, to in map_of_kernel_items:each() do
--   map[#map + 1] = { from.i, from.item.id, from.item.dot, to }
-- end
for i, u in pairs(map_of_kernel_items) do
  for id, v in pairs(u) do
    for dot, to in pairs(v) do
      map[#map + 1] = { i, id, dot, to }
    end
  end
end

table.sort(map, function (a, b)
  for i = 1, #a do
    if a[i] ~= b[i] then
      return a[i] < b[i]
    end
  end
  return false
end)
for i = 1, #map do
  print(map[i][1], map[i][2], map[i][3], map[i][4])
end

writer:write_graph(assert(io.open("test-graph.dot", "w")), transitions):close()
