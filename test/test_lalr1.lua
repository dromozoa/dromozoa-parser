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
local LOOKAHEAD = "#"

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
    if la then
      io.write(", ")
      if type(la) == "number" then
        if la == 0 then
          io.write(EOF)
        elseif la == -2 then
          io.write(LOOKAHEAD)
        else
          io.write(symbols[la])
        end
      else
        local first = true
        for la in la:each() do
          if first then
            first = false
          else
            io.write(" / ")
          end
          if la == 0 then
            io.write(EOF)
          elseif la == -2 then
            io.write(LOOKAHEAD)
          else
            io.write(symbols[la])
          end
        end
      end
    end
    io.write("\n")
  end
end

local _ = grammar()

_"S" (_"L", "=", _"R") (_"R")
_"L" ("*", _"R") ("id")
_"R" (_"L")

local g = _():argument()
-- print(dumper.encode(g, { pretty = true }))

local K = g:lalr1_kernels(dump_items)
for i, items in ipairs(K) do
  io.write(("======== I_%d ==========\n"):format(i))
  dump_items(g, items)
end
