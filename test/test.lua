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
local grammar = require "dromozoa.parser.builder.grammar"
local scanners = require "dromozoa.parser.builder.scanners"
local driver = require "dromozoa.parser.driver"
local dump = require "test.dump"

local _ = scanners()
_"main"
  :pat "%s+" :_"ignore"
  :pat "[1-9]%d*" :as "decimal"
  :pat "0[0-7]*" :as "octal"
  :pat "0x%x+" :as "hexadecimal"
  :lit "*"
  :lit "/"
  :lit "+"
  :lit "-"
  :lit "("
  :lit ")"

local scanners, terminal_symbols = _()

local _ = grammar(terminal_symbols)
_ :left("+", "-")
  :left("*", "/")
  :right(_:prec "UMINUS")

_"E"
  :_(_"E", "-", _"E")
  :_(_"E", "+", _"E")
  :_(_"E", "*", _"E")
  :_(_"E", "/", _"E")
  :_("(", _"E", ")")
  :_("-", _"E") :prec "UMINUS"
  :_("decimal")
  :_("octal")
  :_("hexadecimal")
local grammar = _()
print(dumper.encode(grammar, { pretty = true, stable = true }))

local set_of_items, transitions = grammar:lalr1_items()
dump.write_graph("test-graph.dot", grammar, set_of_items, transitions)
local data = grammar:lr1_construct_table(set_of_items, transitions, io.stdout)
dump.write_table("test.html", grammar, data)

local driver = driver(data)
local source = [[
17 + - 23 * 37 - 42
]]

local position = 1
while true do
  local symbol, i, j = scanners(source, position)
  print(symbol, terminal_symbols[symbol], i, j, source:sub(i, j))
  if symbol == 1 then
    assert(driver:parse())
    break
  else
    assert(driver:parse(symbol, { value = source:sub(i, j) }))
  end
  position = j + 1
end

dump.write_tree("test-tree.dot", grammar, driver.tree)
