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
E' -> E
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])
local actions, gotos = construct_slr(prods, { "E'", sequence():push("E"), 1, { "$" } })

io.write(test.unparse_actions(actions))
io.write(test.unparse_gotos(gotos))
