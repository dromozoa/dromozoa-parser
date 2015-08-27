-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local sequence = require "dromozoa.commons.sequence"
local lr0 = require "dromozoa.parser.lr0"
local test = require "test"

local prods, start = test.parse_grammar([[
E' -> E
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])
start[3] = 1

local goto_items = lr0.goto_(
    prods,
    sequence()
        :push({ "E'", sequence():push("E"), 2 })
        :push({ "E", sequence():push("E", "+", "T"), 2 }),
    "+")
assert(test.unparse_items(goto_items) == [[
E -> E + · T
T -> · T * F
T -> · F
F -> · ( E )
F -> · id
]])

local set_of_items = lr0.items(prods, start)
assert(test.unparse_set_of_items(set_of_items) == [[
I0
  E' -> · E
  E -> · E + T
  E -> · T
  T -> · T * F
  T -> · F
  F -> · ( E )
  F -> · id
I1
  E' -> E ·
  E -> E · + T
I2
  E -> T ·
  T -> T · * F
I3
  T -> F ·
I4
  F -> ( · E )
  E -> · E + T
  E -> · T
  T -> · T * F
  T -> · F
  F -> · ( E )
  F -> · id
I5
  F -> id ·
I6
  E -> E + · T
  T -> · T * F
  T -> · F
  F -> · ( E )
  F -> · id
I7
  T -> T * · F
  F -> · ( E )
  F -> · id
I8
  F -> ( E · )
  E -> E · + T
I9
  E -> E + T ·
  T -> T · * F
I10
  T -> T * F ·
I11
  F -> ( E ) ·
]])
