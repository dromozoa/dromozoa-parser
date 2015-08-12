-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"

local DOT = string.char(0xC2, 0xB7) -- MIDDLE DOT
local EPSILON = string.char(0xCE, 0xB5) -- GREEK SMALL LETTER EPSILON

local class = {}

function class.parse_grammar(text)
  local prods = linked_hash_table()
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*#") then
      local head
      local body = sequence()
      for symbol in line:gmatch("%S+") do
        if symbol == "->" then
          assert(head ~= nil)
          assert(#body == 0)
        else
          if head == nil then
            head = symbol
          else
            body:push(symbol)
          end
        end
      end
      local bodies = prods[head]
      if bodies == nil then
        prods[head] = sequence():push(body)
      else
        bodies:push(body)
      end
    end
  end
  return prods
end

function class.unparse_symbol(out, symbol)
  local t = type(symbol)
  if type(symbol) == "table" then
    if #symbol == 0 then
      out:write(EPSILON)
    else
      out:write(table.concat(symbol))
    end
  else
    out:write(symbol)
  end
  return out
end

function class.unparse_grammar(out, prods)
  for head, bodies in prods:each() do
    class.unparse_symbol(out, head)
    local first = true
    for body in bodies:each() do
      if first then
        first = false
        out:write(" ->")
      else
        out:write(" |")
      end
      if #body == 0 then
        out:write(" ", EPSILON)
      else
        for symbol in body:each() do
          out:write(" ")
          class.unparse_symbol(out, symbol)
        end
      end
    end
    out:write("\n")
  end
  return out
end

return class
