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

local _ = builder()
local P = builder.P
local R = builder.R
local S = builder.S

_ :pat(S" \t\n\v\f\r"^"+") :ignore()
  :pat(R"19" * R"09"^"*") :as "decimal"
  :pat(P"0" * R"07"^"*") :as "octal"
  :pat(P"0x" * R"09A-Fa-f"^"*") :as "hexadecimal"
  :lit "*"
  :lit "/"
  :lit "+"
  :lit "-"
  :lit "("
  :lit ")"

_ :left "+" "-"
  :left "*" "/"
  :right "UMINUS"

_ "E"
  :_ "E" "*" "E"
  :_ "E" "/" "E"
  :_ "E" "+" "E"
  :_ "E" "-" "E"
  :_ "(" "E" ")"
  :_ "-" "E" :prec "UMINUS"
  :_ "decimal"
  :_ "octal"
  :_ "hexadecimal"

local scanner, grammar, writer = _:build()

-- print(dumper.encode(scanner, { pretty = true, stable = true }))
-- print(dumper.encode(grammar, { pretty = true, stable = true }))
-- print(dumper.encode(writer, { pretty = true, stable = true }))

local set_of_items, transitions = grammar:lalr1_items()
-- print(dumper.encode(set_of_items, { pretty = true, stable = true }))
-- for from, to in pairs(transitions) do
--   print(dumper.encode({ from = from, to = to }, { stable = true }))
-- end
writer:write_set_of_items(io.stdout, set_of_items)

writer:write_graph(assert(io.open("test-graph.dot", "w")), transitions):close()
local data, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
writer:write_conflicts(io.stdout, conflicts)
writer:write_table(assert(io.open("test.html", "w")), data):close()

local driver = driver(data)

local source = [[
17 + - 23 * 37 - 42 / 0x69
]]

local position = 1
while true do
  local symbol, i, j = scanner(source, position)
  print(symbol, writer.symbol_names[symbol], i, j, source:sub(i, j))
  if symbol == 1 then
    assert(driver:parse())
    break
  else
    assert(driver:parse(symbol, { value = source:sub(i, j) }))
  end
  position = j + 1
end

writer:write_tree(assert(io.open("test-tree.dot", "w")), driver.tree):close()
