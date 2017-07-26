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

local builder = require "dromozoa.parser.builder"

local _ = builder()

_:lexer()
  :_ "i"
  :_ "e"
  :_ "a"

_ "S"
  :_ "i" "S" "e" "S"
  :_ "i" "S"
  :_ "a"

local lexer, grammar = _:build()
local set_of_items, transitions = grammar:lalr1_items()
grammar:write_set_of_items(io.stdout, set_of_items)
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
-- P.282 Figure 4.51
grammar:write_table("test.html", parser)
grammar:write_conflicts(io.stdout, conflicts, false)
