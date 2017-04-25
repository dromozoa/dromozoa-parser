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

local function dump_items(g, items)
  local productions = g.productions
  local symbols = g.symbols
  for item in items:each() do
    local production = productions[item.id]
    local body = production.body
    local dot = item.dot
    local la = item.la
    io.write(symbols[production.head], " ", TO)
    for i, symbol in ipairs(body) do
      if i == dot then
        io.write(" ", DOT)
      end
      io.write(" ", symbols[symbol])
    end
    if dot == #body + 1 then
      io.write(" ", DOT)
    end
    io.write(", ")
    if la == 0 then
      io.write(EOF)
    else
      io.write(symbols[la])
    end
    io.write("\n")
  end
end

local _ = grammar()

_"S" (_"C", _"C")
_"C" ("c", _"C") ("d")

local g = _():argument()
print(dumper.encode(g, { pretty = true }))

-- S' -> dot S, $
local I = sequence():push({ id = 4, dot = 1, la = 0 })
print("--")
dump_items(g, I)

-- S' -> dot S, $
-- S -> dot C C, $
-- C -> dot c C, c/d
-- C -> dot d, c/d
local J = g:lr1_closure(I)
print("--")
dump_items(g, J)

local set_of_items = g:lr1_items()
for i, items in ipairs(set_of_items) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_items(g, items)
end
