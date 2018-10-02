-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local builder = require "dromozoa.parser.builder"

-- P.262 Figure 4.41
-- P.266 Figure 4.42
-- P.269 Figure 4.43

local _ = builder()

local mode = ...

_:lexer()
  :_ "c"
  :_ "d"

_"S"
  :_ "C" "C"
_"C"
  :_ "c" "C"
  :_ "d"

local lexer, grammar = _:build()

local set_of_items
local transitions
if mode == "lalr1" then
  set_of_items, transitions = grammar:lalr1_items()
else
  set_of_items, transitions = grammar:lr1_items()
end
grammar:write_set_of_items(io.stdout, set_of_items)
grammar:write_graph("test-graph.svg", set_of_items, transitions)

local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
grammar:write_table("test-table.html", parser)
grammar:write_conflicts(io.stderr, conflicts)
