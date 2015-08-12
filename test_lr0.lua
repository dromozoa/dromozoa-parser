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

local equal = require "dromozoa.commons.equal"
local sequence = require "dromozoa.commons.sequence"
local lr0 = require "dromozoa.parser.lr0"
local json = require "dromozoa.json"
local test = require "test"

local prods = test.parse_grammar([[
E' -> E
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])

local goto_items = lr0.goto_(prods, sequence()
  :push(sequence():push("E'", sequence():push("E"), 2))
  :push(sequence():push("E", sequence():push("E", "+", "T"), 2)), "+")
assert(equal(goto_items, {
  { "E", { "E", "+", "T" }, 3 };
  { "T", { "T", "*", "F" }, 1 };
  { "T", { "F" }, 1 };
  { "F", { "(", "E", ")" }, 1 };
  { "F", { "id" }, 1 };
}))

local set_of_items = lr0.items(prods, sequence()
  :push("E'", sequence():push("E"), 1))

for items in set_of_items:each() do
  io.write("----\n")
  io.write(json.encode(items),"\n")
end

