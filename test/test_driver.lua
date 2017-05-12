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
local builder = require "dromozoa.parser.builder"
local driver = require "dromozoa.parser.driver"

local _ = builder()

_ :pat "%s+" :ignore ()
  :pat "%a+" :as "id"
  :lit "+"
  :lit "*"
  :lit "("
  :lit ")"

_ "E"
  :_ "E" "+" "T"
  :_ "T"

_ "T"
  :_ "T" "*" "F"
  :_ "F"

_ "F"
  :_ "(" "E" ")"
  :_ "id"

local scanner, grammar, writer = _:build()
print(dumper.encode(grammar, { pretty = true, stable = true }))

local data = grammar:lr1_construct_table(grammar:lalr1_items())
print(dumper.encode(data, { stable = true }))
writer:write_table(assert(io.open("test.html", "w")), data):close()

local _ = _.symbol_table

local driver = driver(data)
assert(driver:parse(_["("]))
assert(driver:parse(_["id"], { value = 17 }))
assert(driver:parse(_["+"]))
assert(driver:parse(_["id"], { value = 23 }))
assert(driver:parse(_[")"]))
assert(driver:parse(_["+"]))
assert(driver:parse(_["id"], { value = 37 }))
assert(driver:parse())
writer:write_tree(assert(io.open("test-tree.dot", "w")), driver.tree):close()
