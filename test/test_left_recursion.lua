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

local equal = require "dromozoa.commons.equal"
local builder = require "dromozoa.parser.builder"

local _ = builder()

_:lexer()
  :_"a"
  :_"b"
  :_"c"
  :_"d"

_"S"
  :_ "A" "a"
  :_ "b"

_"A"
  :_ "A" "c"
  :_ "S" "d"
  :_ ()

local lexer, grammar = _:build()

local first_table = grammar.first_table

assert(equal(first_table[6], { -- first(S') = { a, b, c }
  [2] = true;
  [3] = true;
  [4] = true;
}))

assert(equal(first_table[7], { -- first(S) = { a, b, c }
  [2] = true;
  [3] = true;
  [4] = true;
}))

assert(equal(first_table[8], { -- first(A) = { a, b, c, epsilon }
  [0] = true;
  [2] = true;
  [3] = true;
  [4] = true;
}))

assert(equal(first_table[9], { -- first(A') = { a, c, epsilon }
  [0] = true;
  [2] = true;
  [4] = true;
}))
