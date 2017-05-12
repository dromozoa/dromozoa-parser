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

_ :lit "i"
  :lit "e"
  :lit "a"

_ "S"
  :_ "i" "S" "e" "S"
  :_ "i" "S"
  :_ "a"

local scanner, grammar, writer = _:build()
print(dumper.encode(g, { pretty = true, stable = true }))

local set_of_items, transitions = grammar:lalr1_items()
writer:write_set_of_items(io.stdout, set_of_items)
writer:write_graph(assert(io.open("test-graph.dot", "w")), transitions):close()

local data, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
writer:write_conflicts(io.stdout, conflicts, true)
writer:write_table(assert(io.open("test.html", "w")), data):close()

local _ = _.symbol_table

local driver = driver(data)
assert(driver:parse(_["i"]))
assert(driver:parse(_["i"]))
assert(driver:parse(_["a"]))
assert(driver:parse(_["e"]))
assert(driver:parse(_["a"]))
assert(driver:parse())
writer:write_tree(assert(io.open("test-tree.dot", "w")), driver.tree):close()
