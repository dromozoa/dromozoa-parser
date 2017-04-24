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

local function dump_items(g, items)
  local productions = g.productions
  local symbols = g.symbols
  for item in items:each() do
    local production = productions[item.id]
    local body = production.body
    local dot = item.dot
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
    io.write("\n")
  end
end

local _ = grammar()

_"E" (_"E", "+", _"T") (_"T")
_"T" (_"T", "*", _"F") (_"F")
_"F" ("(", _"E", ")") ("id")

local g = _():argument()
-- print("--")
-- print(dumper.encode(g, { pretty = true }))

-- E' -> dot E
local I = sequence():push():push({ id = 7, dot = 1 })
-- print("--")
-- print(dumper.encode(I, { pretty = true }))
-- dump_items(g, I)

-- E' -> dot E
-- E -> dot E + T
-- E -> dot T
-- T -> dot T * F
-- T -> dot F
-- F -> dot ( E )
-- F -> dot id
local J = g:lr0_closure(I)
-- print("--")
-- print(dumper.encode(J, { pretty = true }))
-- dump_items(g, J)

-- E' -> E dot
-- E -> E dot + T
local I = sequence()
  :push({ id = 7, dot = 2 })
  :push({ id = 1, dot = 2 })
-- print("--")
-- dump_items(g, I)

-- E -> E + dot T
-- T -> dot T * F
-- T -> dot F
-- F -> dot ( E )
-- F -> dot id
local J = g:lr0_goto(I, 1)
-- print("--")
-- dump_items(g, J)

local C = g:lr0_items()
for i, I in ipairs(C) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_items(g, I)
end
