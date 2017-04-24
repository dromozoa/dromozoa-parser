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

local function dump_set_of_items(g, set_of_items)
  local productions = g.productions
  local symbols = g.symbols
  for items in set_of_items:each() do
    local production = productions[items.production]
    local dot = items[items.dot]
    io.write(symbols[production.head], " ", TO)
    for i = 1, #production.body do
      if i == dot then
        io.write(" ", DOT)
      end
      io.write(" ", symbols[production.body[i]])
    end
    if dot == #production.body + 1 then
      io.write(" ", DOT)
    end
    io.write("\n")
  end
end

local _ = grammar()

_"E" (_"E", "+", _"T") (_"T")
_"T" (_"T", "*", _"F") (_"F")
_"F" ("(", _"E", ")") ("id")

local g = _():argument()
print(dumper.encode(g, { pretty = true }))

-- E' -> dot E
local I = sequence():push():push({ production = 7, dot = 1 })
-- print(dumper.encode(I, { pretty = true }))
local J = g:lr0_closure(I)
-- print(dumper.encode(J, { pretty = true }))

print("--")
dump_set_of_items(g, J)

os.exit()

local I = sequence()
  :push(sequence():push(7, 2))
  :push(sequence():push(1, 2))
-- print("--")
-- dump_set_of_items(g, I)
local J = g:lr0_goto(I, 1)
-- print("--")
-- dump_set_of_items(g, J)

local C = g:lr0_items()
for i, I in ipairs(C) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_set_of_items(g, C[i])
end
