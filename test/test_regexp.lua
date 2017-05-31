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

-- local p = P"a"^"*"
-- local p = (P"X" ^{2,4}) ^"*"
-- local p = P"abcdef"
-- local p = (S"ab"^"*" * P"c"^"?")^"*"
-- local p = (P"a"^"*")^"*"
-- local p = (P"a"*P"b")^{1,3}
local p = P"abcd" + P"aacd"
-- local p = P"if" + "elseif" + "then" + "end" + "while"

print(dumper.encode(p, { pretty = true, stable = ture }))

local data = regexp.tree_to_nfa(p)
local transitions = data.transitions
local epsilons = data.epsilons
local n = data.max_state
-- print(dumper.encode(transitions, { pretty = true, stable = ture }))

-- print(data.start_state, dumper.encode(data.accept_states))

local dfa, epsilon_closures = regexp.nfa_to_dfa(data)
local dfa_transitions = dfa.transitions
local max_dfa = dfa.max_state
local dfa_accepts = dfa.accept_states

-- local epsilon_closures, dfa_transitions, max_dfa, dfa_accepts = regexp.nfa_to_dfa(data)
-- print("--")
-- print(dumper.encode(dfa_transitions, { pretty = true, stable = true }))
-- print(dumper.encode(dfa_accepts, { pretty = true, stable = true }))

regexp_writer.write_automaton(assert(io.open("test-dfa1.dot", "w")), dfa):close()

dfa, partitions = regexp.minimize_dfa(dfa)
local dfa_transitions = dfa.transitions
local max_dfa = dfa.max_state
local dfa_accepts = dfa.accept_states

-- print("--")
-- print(dumper.encode(dfa, { pretty = true, stable = true }))
-- print(dumper.encode(dfa_accepts, { pretty = true, stable = true }))

regexp_writer.write_automaton(assert(io.open("test-nfa.dot", "w")), data):close()

regexp_writer.write_automaton(assert(io.open("test-dfa2.dot", "w")), dfa):close()
