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

local ipairs = require "dromozoa.commons.ipairs"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local EOF = "$"
local LOOKAHEAD = "#"

local class = {}

function class.la(out, g, la)
  local symbols = g.symbols
  if la == 0 then
    out:write(EOF)
  elseif la == -2 then
    out:write(LOOKAHEAD)
  else
    out:write(symbols[la])
  end
end

function class.item(out, g, item)
  local productions = g.productions
  local symbols = g.symbols
  local production = productions[item.id]
  local body = production.body
  local dot = item.dot
  local la = item.la
  out:write(symbols[production.head], " ", TO)
  for i, symbol in ipairs(body) do
    if i == dot then
      out:write(" ", DOT)
    end
    out:write(" ", symbols[symbol])
  end
  if dot == #body + 1 then
    out:write(" ", DOT)
  end
  if la then
    if type(la) == "number" then
      out:write(", ")
      class.la(out, g, la)
    elseif not empty(la) then
      out:write(", ")
      local first = true
      for la in la:each() do
        if first then
          first = false
        else
          out:write(" / ")
        end
        class.la(out, g, la)
      end
    end
  end
  return out
end

function class.items(out, g, items)
  for item in items:each() do
    class.item(out, g, item)
    io.write("\n")
  end
end

function class.set_of_items(out, g, set_of_items)
  for i, items in ipairs(set_of_items) do
    io.write("======== I_", i, " ==========\n")
    class.items(out, g, items)
  end
end

return class
