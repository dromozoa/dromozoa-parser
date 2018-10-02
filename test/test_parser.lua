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
local parser = require "dromozoa.parser.parser"

local _ = builder()

_:lexer()
  :_ "id"
  :_ "+"
  :_ "*"
  :_ "("
  :_ ")"

_ :left "+"
  :left "*"

_"E"
  :_ "E" "+" "E"
  :_ "E" "*" "E"
  :_ "(" "E" ")"
  :_ "id"

local scanner, grammar = _:build()
local parser = grammar:lr1_construct_table(grammar:lalr1_items())
local symbol_table = _.symbol_table

local root = assert(parser({
  { [0] = symbol_table["id"] };
  { [0] = symbol_table["+"] };
  { [0] = symbol_table["id"] };
  { [0] = symbol_table["*"] };
  { [0] = symbol_table["id"] };
  { [0] = 1 }; -- $
}))

assert(root[0] == symbol_table.E)
assert(#root == 3)
assert(root[1][0] == symbol_table.E)
assert(root[2][0] == symbol_table["+"])
assert(root[3][0] == symbol_table.E)
assert(#root[1] == 1)
assert(root[1][1][0] == symbol_table.id)
assert(#root[3] == 3)
assert(root[3][1][0] == symbol_table.E)
assert(root[3][2][0] == symbol_table["*"])
assert(root[3][3][0] == symbol_table.E)
assert(#root[3][1] == 1)
assert(root[3][1][1][0] == symbol_table.id)
assert(#root[3][3] == 1)
assert(root[3][3][1][0] == symbol_table.id)
