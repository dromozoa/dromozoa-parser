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
local driver = require "dromozoa.parser.driver"
local grammar = require "dromozoa.parser.builder.grammar"
local dump = require "test.dump"

local _ = grammar()

-- _"E" (_"E", "+", _"E") (_"E", "*", _"E") ("(", _"E", ")") ("id")
_"E" (_"E", "+", _"E") (_"E", "*", _"E") ("(", _"E", ")") ("+", _"E") ("id")
-- _"S" ("i", _"S", "e", _"S") ("i", _"S") ("a")

local g = _()
print(dumper.encode(g, { pretty = true, stable = true }))

local set_of_items, transitions = g:lalr1_items()
dump.set_of_items(io.stdout, g, set_of_items)
dump.write_graph("test.dot", g, set_of_items, transitions)

local data = g:lr1_construct_table(set_of_items, transitions, io.stdout)
dump.write_table("test.html", g, data)

local _ = {}
for i, name in ipairs(g.symbols) do
  _[name] = i
end

local d = driver(g, data)
assert(d:parse(_["("]))
assert(d:parse(_["id"], { value = 17 }))
assert(d:parse(_["+"]))
assert(d:parse(_["+"]))
assert(d:parse(_["id"], { value = 23 }))
assert(d:parse(_[")"]))
assert(d:parse(_["*"]))
assert(d:parse(_["id"], { value = 37 }))
assert(d:parse())
dump.write_tree("test.dot", g, d.tree)
