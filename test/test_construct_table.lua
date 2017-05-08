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
local xml = require "dromozoa.commons.xml"
local grammar = require "dromozoa.parser.builder.grammar"
local dump = require "test.dump"

local _ = grammar()

-- _"E" (_"E", "+", _"T")
-- _"E" (_"T")
-- _"T" (_"T", "*", _"F")
-- _"T" (_"F")
-- _"F" ("(", _"E", ")")
-- _"F" ("id")

_"S" (_"C", _"C")
_"C" ("c", _"C") ("d")

local g = _()

local symbols = g.symbols
local set_of_items, transitions = g:lalr1_items()
local data = g:lr1_construct_table(set_of_items, transitions)
-- print(dumper.encode(data, { stable = true }))

dump.write_table("test.html", g, data)
