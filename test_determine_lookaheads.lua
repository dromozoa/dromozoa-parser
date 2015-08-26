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
local test = require "test"

local prods = test.parse_grammar([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])

local generate, propagate = determine_lookaheads(prods, { "S'", sequence():push("S"), 1 })
assert(test.unparse_lookaheads(generate, propagate) == [[
generate L -> * · R
  =
generate L -> id ·
  =
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
