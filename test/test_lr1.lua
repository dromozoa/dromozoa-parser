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

local dumper = require "dromozoa.commons.dumper"
local sequence = require "dromozoa.commons.sequence"
local grammar = require "dromozoa.parser.builder.grammar"
local dump = require "test.dump"

local _ = grammar()

_"S" (_"C", _"C")
_"C" ("c", _"C") ("d")

local g = _()
print(dumper.encode(g, { pretty = true, stable = true }))

-- S' -> dot S, $
local I = sequence():push({ id = 4, dot = 1, la = 1 })
print("--")
dump.items(io.stdout, g, I)

-- S' -> dot S, $
-- S -> dot C C, $
-- C -> dot c C, c/d
-- C -> dot d, c/d
g:lr1_closure(I)
print("--")
dump.items(io.stdout, g, I)

local set_of_items, transitions = g:lr1_items()
dump.set_of_items(io.stdout, g, set_of_items)
dump.write_graph("test.dot", g, set_of_items, transitions)
