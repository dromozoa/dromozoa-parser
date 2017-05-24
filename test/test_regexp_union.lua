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

local regexp = require "dromozoa.parser.regexp"
local regexp_builder = require "dromozoa.parser.regexp_builder"
local regexp_writer = require "dromozoa.parser.regexp_writer"

local P = regexp_builder.P
local R = regexp_builder.R
local S = regexp_builder.S

local nfa1 = regexp.tree_to_nfa(P"abcd", 1)
local nfa2 = regexp.tree_to_nfa(P"aaaa", 2)
local nfa3 = regexp.tree_to_nfa(P"a"^"+", 3)
local nfa4 = regexp.tree_to_nfa(R("ad")^"+", 4)

regexp.union(nfa1, nfa2)
regexp.union(nfa1, nfa3)
regexp.union(nfa1, nfa4)

regexp_writer.write_automaton(assert(io.open("test-nfa.dot", "w")), nfa1):close()

local dfa1 = regexp.nfa_to_dfa(nfa1)

regexp_writer.write_automaton(assert(io.open("test-dfa1.dot", "w")), dfa1):close()

local dfa2 = regexp.minimize_dfa(dfa1)

regexp_writer.write_automaton(assert(io.open("test-dfa2.dot", "w")), dfa2):close()

