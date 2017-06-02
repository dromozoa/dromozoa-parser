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

local keys = require "dromozoa.commons.keys"
local dumper = require "dromozoa.commons.dumper"
local unpack = require "dromozoa.commons.unpack"
local builder = require "dromozoa.parser.builder_v2"
local regexp = require "dromozoa.parser.regexp"
local regexp_builder = require "dromozoa.parser.regexp_builder"
local regexp_writer = require "dromozoa.parser.regexp_writer"

local P = builder.pattern
local R = builder.range
local S = builder.set

-- local p = P"abcd" + P"aacd"
-- local p = P"xyz"^"*" + P"abcd" + P"aaaa" + P"abca"
-- local p = P"abc"^"+" + P"abc"^2 + P"abc"^3
-- local p = S"abc"^"*" * P"abc" * S"abc"^"*"

local a1 = regexp.minimize(regexp.nfa_to_dfa(regexp.tree_to_nfa(S"abc"^"*")))
regexp_writer.write_automaton(assert(io.open("test-a1.dot", "w")), a1):close()
local a2 = regexp.nfa_to_dfa(regexp.tree_to_nfa(S"abc"^"*" * P"ccc" * S"abc"^"*"))
regexp_writer.write_automaton(assert(io.open("test-a2-0.dot", "w")), a2):close()
print("minimize a2")
local a2 = regexp.minimize(a2)
regexp_writer.write_automaton(assert(io.open("test-a2.dot", "w")), a2):close()
local a3 = regexp.difference(a1, a2)
regexp_writer.write_automaton(assert(io.open("test-a3.dot", "w")), a3):close()
print("minimize a3")
local a4 = regexp.minimize(a3)
regexp_writer.write_automaton(assert(io.open("test-a4.dot", "w")), a4):close()


local p = P"cba" * (S"abc"^"*" - S"abc"^"*" * P"ccc" * S"abc"^"*") * P"abc"
local nfa = regexp.tree_to_nfa(p)
regexp_writer.write_automaton(assert(io.open("test-nfa.dot", "w")), nfa):close()
local dfa1 = regexp.nfa_to_dfa(nfa)
local dfa2 = regexp.minimize(dfa1)
regexp_writer.write_automaton(assert(io.open("test-dfa1.dot", "w")), dfa1):close()
regexp_writer.write_automaton(assert(io.open("test-dfa2.dot", "w")), dfa2):close()
