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
local grammar = require "dromozoa.parser.grammar"
local scanner = require "dromozoa.parser.scanner"
local dump = require "test.dump"

local _ = builder()

_ :pat "%s+" :ignore ()
  :pat "[1-9]%d*" :as "decimal"
  :pat "0[0-7]*" :as "octal"
  :pat "0x%x+" :as "hexadecimal"
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
  :_ "E" "-" "E"
  :_ "E" "+" "E"
  :_ "E" "*" "E"
  :_ "E" "/" "E"
  :_ "(" "E" ")"
  :_ "-" "E" :prec "UMINUS"
  :_ "decimal"
  :_ "octal"
  :_ "hexadecimal"

local data = _:build()

print(dumper.encode(data, { pretty = true, stable = true }))

local grammar = grammar(
    data.symbols,
    data.productions,
    data.max_terminal_symbol,
    data.max_nonterminal_symbol,
    data.symbol_precedences,
    data.production_precedences)

print(dumper.encode(grammar, { pretty = true, stable = true }))

local set_of_items, transitions = grammar:lalr1_items()
print(dumper.encode(set_of_items, { pretty = true, stable = true }))
print(dumper.encode(transitions, { pretty = true, stable = true }))

dump.write_graph("test-graph.dot", grammar, set_of_items, transitions)
local parser = grammar:lr1_construct_table(set_of_items, transitions, io.stdout)
dump.write_table("test.html", grammar, parser)

local driver = driver(parser)
local scanner = scanner(data.scanners)

local source = [[
17 + - 23 * 37 - 42
]]

local position = 1
while true do
  local symbol, i, j = scanner(source, position)
  print(symbol, data.symbols[symbol], i, j, source:sub(i, j))
  if symbol == 1 then
    assert(driver:parse())
    break
  else
    assert(driver:parse(symbol, { value = source:sub(i, j) }))
  end
  position = j + 1
end

dump.write_tree("test-tree.dot", grammar, driver.tree)
