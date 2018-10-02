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

local _ = builder()

_:lexer()
  :_ "A"

_"list"
  :_ "A" :attr "list"
  :_ "list" "A" {[1]={2}} :attr(2, "attr")

local lexer, grammar = _:build()
local set_of_items, transitions = grammar:lalr1_items()
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)

local root = assert(parser(assert(lexer "AAAA"), source))
assert(root.list == true)
assert(root[1].attr == nil)
assert(root[2].attr == true)
assert(root[3].attr == true)
assert(root[4].attr == true)
