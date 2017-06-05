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

local a1 = regexp(S"abc"^"*"):nfa_to_dfa():minimize()
regexp_writer.write_automaton(assert(io.open("test-a1.dot", "w")), a1):close()
local a2 = regexp(S"abc"^"*" * P"ccc" * S"abc"^"*"):nfa_to_dfa()
regexp_writer.write_automaton(assert(io.open("test-a2-0.dot", "w")), a2):close()
local a2 = a2:minimize()
regexp_writer.write_automaton(assert(io.open("test-a2.dot", "w")), a2):close()
local a3 = a1:difference(a2)
regexp_writer.write_automaton(assert(io.open("test-a3.dot", "w")), a3):close()
local a4 = a3:minimize()
regexp_writer.write_automaton(assert(io.open("test-a4.dot", "w")), a4):close()

local p = P"cba" * (S"abc"^"*" - S"abc"^"*" * P"ccc" * S"abc"^"*") * P"abc"
local nfa = regexp(p)
regexp_writer.write_automaton(assert(io.open("test-nfa.dot", "w")), nfa):close()
local dfa1 = nfa:nfa_to_dfa()
local dfa2 = dfa1:minimize()
regexp_writer.write_automaton(assert(io.open("test-dfa1.dot", "w")), dfa1):close()
regexp_writer.write_automaton(assert(io.open("test-dfa2.dot", "w")), dfa2):close()
