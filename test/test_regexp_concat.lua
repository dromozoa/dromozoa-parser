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

local builder = require "dromozoa.parser.builder_v2"
local regexp = require "dromozoa.parser.regexp"
local regexp_writer = require "dromozoa.parser.regexp_writer"

local P = builder.pattern
local R = builder.range
local S = builder.set

local a1 = regexp.tree_to_nfa(P"abc"^"+", 1)
local a2 = regexp.tree_to_nfa(P"def"^"?", 2)

-- a1 = regexp.minimize(regexp.nfa_to_dfa(a1))
-- a2 = regexp.minimize(regexp.nfa_to_dfa(a2))

regexp_writer.write_automaton(assert(io.open("test-a1.dot", "w")), a1):close()
regexp_writer.write_automaton(assert(io.open("test-a2.dot", "w")), a2):close()

regexp.concat(a1, a2)

regexp_writer.write_automaton(assert(io.open("test-concat.dot", "w")), a1):close()

local dfa1 = regexp.nfa_to_dfa(a1)

regexp_writer.write_automaton(assert(io.open("test-dfa1.dot", "w")), dfa1):close()

local dfa2 = regexp.minimize(dfa1)

regexp_writer.write_automaton(assert(io.open("test-dfa2.dot", "w")), dfa2):close()
