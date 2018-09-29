-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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
local to_graph = require "dromozoa.parser.regexp.to_graph"

local vecmath = require "dromozoa.vecmath"

local dom = require "dromozoa.dom"
local svg = require "dromozoa.svg"

local P = builder.pattern
local R = builder.range
local S = builder.set

local _ = dom.element
local path_data = svg.path_data

local p = P"/*" * (P(1)^"*" - P(1)^"*" * P"*/" * P(1)^"*") * P"*/"
-- local p = R"az"^"*"
-- local p
--   = P"あ" + P"い" + P"う" + P"え" + P"お"
--   + P"わ" + P"を" + P"ん"
-- local p = (R"09"^"+" * (P"." * R"09"^"*")^"?" + P"." * R"09"^"+") * (S"eE" * S"+-"^"?" * R"09"^"+")^"?"
-- local p = (P"if" + P"then" + P"elseif" + P"else" + P"end")^"+"

local nfa = regexp(p)
nfa:write_svg "test-nfa.svg"

local dfa = nfa:nfa_to_dfa():minimize()
dfa:write_svg "test-dfa.svg"
