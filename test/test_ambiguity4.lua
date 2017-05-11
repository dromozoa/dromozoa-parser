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

_ :lit "word"

_ "sequence"
  :_ ()
  :_ "maybeword"
  :_ "sequence" "word"

_ "maybeword"
  :_ ()
  :_ "word"

local scanner, grammar, writer = _:build()

local set_of_items, transitions = grammar:lalr1_items()

writer:write_set_of_items(io.stdout, set_of_items)
writer:write_graph(assert(io.open("test-graph.dot", "w")), transitions):close()

local data, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
writer:write_conflicts(io.stdout, conflicts)
writer:write_table(assert(io.open("test.html", "w")), data):close()
