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

local clone = require "dromozoa.commons.clone"
local sequence = require "dromozoa.commons.sequence"
local determine_lookaheads = require "dromozoa.parser.determine_lookaheads"
local lalr_kernel_items = require "dromozoa.parser.lalr_kernel_items"
local lr0_kernel_items = require "dromozoa.parser.lr0_kernel_items"
local test = require "test"

local prods, start = test.parse_grammar([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])
start[3] = 1

local set_of_kernel_items = lr0_kernel_items(prods, start)

local generate, propagate = determine_lookaheads(prods, start, set_of_kernel_items)
assert(test.unparse_lookaheads_generate(generate) == [[
generate S' -> · S
  $
generate L -> * · R
  =
generate L -> id ·
  =
]])
assert(test.unparse_lookaheads_propagate(propagate) == [[
propagate S' -> S ·
  S' -> · S
propagate S -> L · = R
  S' -> · S
propagate S -> R ·
  S' -> · S
propagate R -> L ·
  S' -> · S
  L -> * · R
  S -> L = · R
propagate L -> * · R
  S' -> · S
  L -> * · R
  S -> L = · R
propagate L -> id ·
  S' -> · S
  L -> * · R
  S -> L = · R
propagate S -> L = · R
  S -> L · = R
propagate L -> * R ·
  L -> * · R
propagate S -> L = R ·
  S -> L = · R
]])

local generate = lalr_kernel_items(prods, start, set_of_kernel_items)
io.write(test.unparse_lookaheads_generate(generate))
