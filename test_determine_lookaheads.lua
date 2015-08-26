-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local clone = require "dromozoa.commons.clone"
local sequence = require "dromozoa.commons.sequence"
local determine_lookaheads = require "dromozoa.parser.determine_lookaheads"
local test = require "test"

local prods = test.parse_grammar([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])

local lookaheads = determine_lookaheads(prods, { "S'", sequence():push("S"), 1 })

for la in lookaheads:each() do
  local to, from, symbol = clone(la[1]), clone(la[2]), la[3]
  if from == nil then
    io.write("generated ", test.unparse_item(to))
  else
    from[4] = nil
    to[4] = nil
    io.write("propagate ", test.unparse_item(from), " : ", test.unparse_item(to))
  end
  io.write("\n")
end

