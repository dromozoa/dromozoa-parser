-- Copyright (C) 2017-2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local RE = builder.regexp

local p1 = RE[[\s*[+\-]?[0-9]+\s*]]
local p2 = RE[[\s*[+\-]?0[Xx][0-9A-Fa-f]+\s*]]
local a1 = regexp(p1, 1):nfa_to_dfa():minimize()
local a2 = regexp(p2, 2):nfa_to_dfa():minimize()

a1:union(a2):nfa_to_dfa():minimize():write_graph "test-dfa.svg"
