-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

-- P.213 Equation 4.18

local _ = builder()

_:lexer()
  :_ "a"
  :_ "b"
  :_ "c"
  :_ "d"

_"S"
  :_ "A" "a"
  :_ "b"

_"A"
  :_ "A" "c"
  :_ "S" "d"
  :_ ()

--[[
_"S'"
  :_ "S"

_"S"
  :_ "A" "a"
  :_ "b"

_"A"
  :_ "b" "d" "A'"
  :_ "A'"

_"A'"
  :_ "c" "A'"
  :_ "a" "d" "A'"
  :_ ()
]]


local lexer, grammar = _:build()
local grammar = grammar:eliminate_left_recursion()
local first_table = grammar:first()
local symbol_names = grammar.symbol_names

local symbol_table = {}
for i = 1, #symbol_names do
  local name = symbol_names[i]
  assert(not symbol_table[name])
  symbol_table[name] = i
end

local function test(name, data)
  local first = first_table[symbol_table[name]]
  local expected = {}
  for i = 1, #data do
    local item = data[i]
    if type(item) == "string" then
      expected[symbol_table[item]] = true
    else
      expected[item] = true
    end
  end
  for k, v in pairs(first) do
    assert(expected[k])
  end
  for k, v in pairs(expected) do
    assert(first[k])
  end
end

local epsilon = 0
test("S'", { "a", "b", "c" })
test("S",  { "a", "b", "c" })
test("A",  { "a", "b", "c", epsilon })
test("A'", { "a", "c", epsilon })
