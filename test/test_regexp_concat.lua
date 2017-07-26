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
local regexp = require "dromozoa.parser.regexp"

local P = builder.pattern
local R = builder.range
local S = builder.set

local a1 = regexp(P"abc"^"+", 1)
local a2 = regexp(P"def"^"?", 2)
a1:write_graphviz("test-a1.dot")
a2:write_graphviz("test-a2.dot")

a1:concat(a2)
a1:write_graphviz("test-concat.dot")

local dfa1 = a1:nfa_to_dfa()
dfa1:write_graphviz("test-dfa1.dot")

local dfa2 = dfa1:minimize()
dfa2:write_graphviz("test-dfa2.dot")

local dfa3 = regexp(P"abc"^"+" * P"def"^"?", 2):nfa_to_dfa():minimize()
dfa3:write_graphviz("test-dfa3.dot")

assert(equal(dfa2, dfa3))
