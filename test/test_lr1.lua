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
local ipairs = require "dromozoa.commons.ipairs"
local sequence = require "dromozoa.commons.sequence"
local grammar = require "dromozoa.parser.builder.grammar"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local EOF = "$"

local function dump_set_of_items(g, set_of_items)
  local productions = g.productions
  local symbols = g.symbols
  for items in set_of_items:each() do
    local production = productions[items[1]]
    local dot = items[2]
    local a = items[3]
    io.write(symbols[production[1]], " ", TO)
    for i = 2, #production do
      if i == dot then
        io.write(" ", DOT)
      end
      io.write(" ", symbols[production[i]])
    end
    if dot == #production + 1 then
      io.write(" ", DOT)
    end
    io.write(", ")
    if a == 0 then
      io.write(EOF)
    else
      io.write(symbols[a])
    end
    io.write("\n")
  end
end

local _ = grammar()

_"S" (_"C", _"C")
_"C" ("c", _"C") ("d")

local g = _():argument()
print(dumper.encode(g, { pretty = true }))

local I = sequence():push(sequence():push(4, 2, 0)) -- S' -> dot S , $
print("--")
dump_set_of_items(g, I)

local J = g:lr1_closure(I)
print("--")
dump_set_of_items(g, J)

local C = g:lr1_items()
for i, I in ipairs(C) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_set_of_items(g, C[i])
end
