-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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
local S = builder.set

local nfa1 = regexp(P"abc"^"+", 1)
local nfa2 = regexp(P"def"^"?", 2)
nfa1:write_graph "test-nfa1.svg"
nfa2:write_graph "test-nfa2.svg"
nfa1:concat(nfa2)
nfa1:write_graph "test-nfa3.svg"
nfa1:nfa_to_dfa():write_graph "test-dfa1.svg"
nfa1:nfa_to_dfa():minimize():write_graph "test-dfa2.svg"
regexp(P"abc"^"+" * P"def"^"?", 2):nfa_to_dfa():minimize():write_graph "test-dfa3.svg"

local handle = assert(io.open "test-dfa2.svg")
local test2 = handle:read "*a"
handle:close()
local handle = assert(io.open "test-dfa3.svg")
local test3 = handle:read "*a"
handle:close()
assert(test2 == test3)
