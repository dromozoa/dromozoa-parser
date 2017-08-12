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

local RE = builder.regexp

local re1 = regexp(RE[[--\[=*\[.*]], 0):nfa_to_dfa():minimize()
local re2 = regexp(RE[[--[^\n]*\n]], 1):nfa_to_dfa():minimize()
local re = re1:union(re2):nfa_to_dfa():minimize()
for k, v in pairs(re.accept_states) do
  if v == 0 then
    re.accept_states[k] = nil
  end
end
re:minimize():write_graphviz("test-re.dot")

local re3 = regexp(RE[[--(([^\n\[][^\n]*|\[([^\n\[=][^\n]*|=*([^\n\[=][^\n]*)?)?)?)?\n]])
re3:nfa_to_dfa():minimize():write_graphviz("test-re3.dot")

local re4 = regexp(RE[[--[^\n]*\n]] - RE[=[--\[=*\[[^\n]*\n]=])
re4:nfa_to_dfa():minimize():write_graphviz("test-re4.dot")

local re5 = regexp("--" * (RE[[[^\n]*]] - RE[[\[=*\[.*]]) * "\n")
re5:nfa_to_dfa():minimize():write_graphviz("test-re5.dot")

-- re:nfa_to_dfa():minimize():write_graphviz("test-re.dot")
-- re1:nfa_to_dfa() -- :minimize():write_graphviz("test-dfa.dot")
