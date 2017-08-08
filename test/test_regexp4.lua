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
local RE = builder.regexp

local _ = builder()

local p1 = P"[" * P"="^"*" * "[\n"
local p2 = RE[[\[=*\[\n]]

local p1 = (R"09"^"+" * (P"." * R"09"^"*")^"?" + P"." * R"09"^"+") * (S"eE" * S"+-"^"?" * R"09"^"+")^"?"
local p2 = RE[[(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?]]

regexp(p1):nfa_to_dfa():minimize():write_graphviz("test-dfa1.dot")
regexp(p2):nfa_to_dfa():minimize():write_graphviz("test-dfa2.dot")
