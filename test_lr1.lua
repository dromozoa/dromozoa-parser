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
local lr1 = require "dromozoa.parser.lr1"
local test = require "test"

local prods, start = test.parse_grammar([[
S' -> S
S -> C C
C -> c C
C -> d
]])
start[3] = 1
start[4] = { "$" }

local items = lr1.closure(prods, sequence({ start }))
assert(test.unparse_items(items) == [[
S' -> · S, $
S -> · C C, $
C -> · c C, c
C -> · c C, d
C -> · d, c
C -> · d, d
]])

local goto_items = lr1.goto_(prods, items, "S")
assert(test.unparse_items(goto_items) == [[
S' -> S ·, $
]])

local set_of_items = lr1.items(prods, start)
assert(test.unparse_set_of_items(set_of_items) == [[
I0
  S' -> · S, $
  S -> · C C, $
  C -> · c C, c
  C -> · c C, d
  C -> · d, c
  C -> · d, d
I1
  S' -> S ·, $
I2
  S -> C · C, $
  C -> · c C, $
  C -> · d, $
I3
  C -> c · C, c
  C -> c · C, d
  C -> · c C, c
  C -> · d, c
  C -> · c C, d
  C -> · d, d
I4
  C -> d ·, c
  C -> d ·, d
I5
  S -> C C ·, $
I6
  C -> c · C, $
  C -> · c C, $
  C -> · d, $
I7
  C -> d ·, $
I8
  C -> c C ·, c
  C -> c C ·, d
I9
  C -> c C ·, $
]])
