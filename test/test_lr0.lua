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

_"E" (_"E", "+", _"T") (_"T")
_"T" (_"T", "*", _"F") (_"F")
_"F" ("(", _"E", ")") ("id")

local g = _()
-- print("--")
-- print(dumper.encode(g, { pretty = true }))

-- E' -> dot E
local I = sequence():push():push({ id = 7, dot = 1 })
-- print("--")
-- print(dumper.encode(I, { pretty = true }))
-- dump.items(io.stdout, g, I)

-- E' -> dot E
-- E -> dot E + T
-- E -> dot T
-- T -> dot T * F
-- T -> dot F
-- F -> dot ( E )
-- F -> dot id
g:lr0_closure(I)
-- print("--")
-- print(dumper.encode(I, { pretty = true }))
-- dump.items(io.stdout, g, I)

-- E' -> E dot
-- E -> E dot + T
local I = sequence()
  :push({ id = 7, dot = 2 })
  :push({ id = 1, dot = 2 })
-- print("--")
-- dump.items(io.stdout, g, I)

-- E -> E + dot T
-- T -> dot T * F
-- T -> dot F
-- F -> dot ( E )
-- F -> dot id
local J = g:lr0_goto(I)[1]
-- print("--")
-- dump.items(io.stdout, g, J)

local set_of_items, transitions = g:lr0_items()
dump.set_of_items(io.stdout, g, set_of_items)
dump.write_graph("test.dot", g, set_of_items, transitions)
