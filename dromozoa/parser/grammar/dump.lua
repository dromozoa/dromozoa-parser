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

local dumper = require "dromozoa.commons.dumper"
local empty = require "dromozoa.commons.empty"
local ipairs = require "dromozoa.commons.ipairs"

local function dump_symbol(out, symbol)
  local t = type(symbol)
  if t == "string" and symbol:match("^[%a_][%w_]*$") then
    out:write("b.", symbol)
  else
    out:write("b[")
    dumper.write(out, symbol)
    out:write("]")
  end
end

return function (out, this)
  local prods = this.prods
  local start = this.start

  out:write([[
(function ()
  local parser = require "dromozoa.parser"
  local t = parser.syntax_tree()
  local b = t:builder()
]])

  for head, bodies in prods:each() do
    out:write("  ")
    dump_symbol(out, head)
    out:write("\n")
    for i, body in ipairs(bodies) do
      if i == 1 then
        out:write("      =")
      else
        out:write("      +")
      end
      if empty(body) then
        out:write(" b()")
      else
        for j, symbol in ipairs(body) do
          if j == 1 then
            out:write(" ")
          else
            out:write(" * ")
          end
          dump_symbol(out, symbol)
        end
      end
      out:write("\n")
    end
  end

  out:write("  return t:to_grammar(")
  dumper.write(out, start)
  out:write(")\n", [[
end)()
]])

  return out
end
