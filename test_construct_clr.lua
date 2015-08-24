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
local construct_clr = require "dromozoa.parser.construct_clr"
local test = require "test"

local prods = test.parse_grammar([[
S' -> S
S -> C C
C -> c C
C -> d
]])

local actions, gotos = construct_clr(prods, { "S'", sequence():push("S"), 1, { "$" } })
assert(test.unparse_actions(actions) == [[
0 c : shift 3
0 d : shift 4
1 $ : accept
2 c : shift 6
2 d : shift 7
3 c : shift 3
3 d : shift 4
4 c : reduce C -> d
4 d : reduce C -> d
5 $ : reduce S -> C C
6 c : shift 6
6 d : shift 7
7 $ : reduce C -> d
8 c : reduce C -> c C
8 d : reduce C -> c C
9 $ : reduce C -> c C
]])

assert(test.unparse_gotos(gotos) == [[
0 S : 1
0 C : 2
2 C : 5
3 C : 8
6 C : 9
]])
