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

local builder = require "dromozoa.parser.builder"
local regexp = require "dromozoa.parser.regexp"

local P = builder.pattern
local R = builder.range
local S = builder.set

local a1 = regexp(P"abcd", 1):nfa_to_dfa():minimize()
-- local a1 = regexp(S"abc"^"*" * P"abc" * S"abc"^"*")
local a2 = regexp(P"aaaa", 2):nfa_to_dfa():minimize()
-- local a2 = regexp(S"abc"^"*")
local a3 = regexp(P"abba", 3):nfa_to_dfa():minimize()
-- local a3 = regexp(P"x"^"*", 3):nfa_to_dfa():minimize()
local a4 = regexp(P"dddd", 4):nfa_to_dfa():minimize()
-- local a4 = regexp(R("ad")^"+", 4):nfa_to_dfa():minimize()

-- a1 = regexp.minimize(regexp.nfa_to_dfa(a1))
-- a2 = regexp.minimize(regexp.nfa_to_dfa(a2))
-- a3 = regexp.minimize(regexp.nfa_to_dfa(a3))
-- a4 = regexp.minimize(regexp.nfa_to_dfa(a4))

regexp.union(a1, a2)
regexp.union(a1, a3)
regexp.union(a1, a4)

a1:write_graphviz("test-nfa.dot")

local dfa1 = regexp.nfa_to_dfa(a1)

dfa1:write_graphviz("test-dfa1.dot")

local dfa2 = regexp.minimize(dfa1)

dfa2:write_graphviz("test-dfa2.dot")
