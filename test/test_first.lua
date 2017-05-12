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

local EPSILON = string.char(0xCE, 0xB5) -- U+03B5 GREEK SMALL LETTER EPSILON

local function dump_first(symbol_names, first)
  local count = 0
  io.write("{")
  for symbol in first:each() do
    count = count + 1
    if count > 1 then
      io.write(", ")
    end
    if symbol == 0 then
      io.write(EPSILON)
    else
      io.write(symbol_names[symbol])
    end
  end
  io.write("}\n")
end

local _ = builder()

_ :pat "%s+" :ignore ()
  :pat "%a+" :as "id"
  :lit "+"
  :lit "*"
  :lit "("
  :lit ")"

_ "E"
  :_ "T" "E'"
_ "E'"
  :_ "+" "T" "E'"
  :_ ()
_ "T"
  :_ "F" "T'"
_ "T'"
  :_ "*" "F" "T'"
  :_ ()
_ "F"
  :_ "(" "E" ")"
  :_ "id"

local scanner, grammar = _:build()
print(dumper.encode(grammar, { pretty = true, stable = true }))

local N = _.symbol_names
local T = _.symbol_table
dump_first(N, grammar:first_symbol(T["F"])) -- FIRST(F) -> (, id
dump_first(N, grammar:first_symbol(T["T"])) -- FIRST(T) -> (, id
dump_first(N, grammar:first_symbol(T["E"])) -- FIRST(E) -> (, id
dump_first(N, grammar:first_symbol(T["E'"])) -- FIRST(E') -> +, epsilon
dump_first(N, grammar:first_symbol(T["T'"])) -- FIRST(T') -> *, epsilon
