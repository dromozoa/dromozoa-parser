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
local lr0_kernel_items = require "dromozoa.parser.lr0_kernel_items"
local test = require "test"

local prods = test.parse_grammar([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])

local set_of_kernel_items = lr0_kernel_items(prods, { "S'", sequence():push("S"), 1 })
assert(test.unparse_set_of_items(set_of_kernel_items) == [[
I0
  S' -> · S
I1
  S' -> S ·
I2
  S -> L · = R
  R -> L ·
I3
  S -> R ·
I4
  L -> * · R
I5
  L -> id ·
I6
  S -> L = · R
I7
  R -> L ·
I8
  L -> * R ·
I9
  S -> L = R ·
]])
