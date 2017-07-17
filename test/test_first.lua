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
local equal = require "dromozoa.commons.equal"
local builder = require "dromozoa.parser.builder"

local _ = builder()

_:lexer()
  :_"id"
  :_"+"
  :_"*"
  :_"("
  :_")"

_"E"
  :_ "T" "E'"
_"E'"
  :_ "+" "T" "E'"
  :_ ()
_"T"
  :_ "F" "T'"
_"T'"
  :_ "*" "F" "T'"
  :_ ()
_"F"
  :_ "(" "E" ")"
  :_ "id"

local lexer, grammar = _:build()

print(dumper.encode(grammar, { pretty = true, stable = true }))

local function test(name, data)
  local first = grammar:first_symbol(_.symbol_table[name])
  print(dumper.encode(first, { stable = true }))
  local expected = {}
  for i = 1, #data do
    local item = data[i]
    if type(item) == "string" then
      expected[_.symbol_table[item]] = true
    else
      expected[item] = true
    end
  end
  assert(equal(first, expected))
end

local epsilon = 0
test("F", { "(", "id" })
test("T", { "(", "id" })
test("E", { "(", "id" })
test("E'", { "+", epsilon })
test("T'", { "*", epsilon })
