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
local grammar = require "dromozoa.parser.builder.grammar"

local EPSILON = string.char(0xCE, 0xB5) -- U+03B5 GREEK SMALL LETTER EPSILON

local function dump_first(g, f)
  local symbols = g.symbols
  local count = 0
  io.write("{")
  for symbol in f:each() do
    count = count + 1
    if count > 1 then
      io.write(", ")
    end
    if symbol == 0 then
      io.write(EPSILON)
    else
      io.write(symbols[symbol])
    end
  end
  io.write("}\n")
end

local _ = grammar()

_"E"  (_"T", _"E'")
_"E'" ("+", _"T", _"E'") ()
_"T"  (_"F", _"T'")
_"T'" ("*", _"F", _"T'") ()
_"F"  ("(", _"E", ")") ("id")

local g = _()
-- print(dumper.encode(g, { pretty = true }))

dump_first(g, g:first_symbol(9)) -- FIRST(F) -> (, id
dump_first(g, g:first_symbol(7)) -- FIRST(T) -> (, id
dump_first(g, g:first_symbol(6)) -- FIRST(E) -> (, id
dump_first(g, g:first_symbol(8)) -- FIRST(E') -> +, epsilon
dump_first(g, g:first_symbol(10)) -- FIRST(T') -> *, epsilon
