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
local construct_slr = require "dromozoa.parser.construct_clr"
local make_followset = require "dromozoa.parser.make_followset"
local test = require "test"

local prods = test.parse_grammar([[
S -> E
E -> 1 E
E -> 1
]])
local start = { "E'", sequence():push("E"), 1, { "$" } }

local actions, gotos = construct_slr(prods, start)
assert(test.unparse_actions(actions) == [[
0 1 : shift 2
1 $ : accept
2 $ : reduce E -> 1
2 1 : shift 2
3 $ : reduce E -> 1 E
]])
assert(test.unparse_gotos(gotos) == [[
0 E : 1
2 E : 3
]])
