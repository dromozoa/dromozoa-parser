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
local xml = require "dromozoa.commons.xml"
local grammar = require "dromozoa.parser.builder.grammar"

local _ = grammar()

-- _"E" (_"E", "+", _"T")
-- _"E" (_"T")
-- _"T" (_"T", "*", _"F")
-- _"T" (_"F")
-- _"F" ("(", _"E", ")")
-- _"F" ("id")

_"S" (_"C", _"C")
_"C" ("c", _"C") ("d")

local g = _()

local symbols = g.symbols
local set_of_items, transitions = g:lr0_items()
local set_of_items = g:lalr1_kernels(set_of_items, transitions)
for items in set_of_items:each() do
  g:lr1_closure(items)
end

local data = g:lr1_construct_table(set_of_items, transitions)
-- print(dumper.encode(data, { stable = true }))

local max_state = data.max_state
local max_symbol = data.max_symbol
local table = data.table

io.write([[
<style>
  td {
    border: 1px solid #ccc;
  }
</style>
<table>
]])

io.write("  <tr>\n")
io.write("    <td rowspan=\"2\">STATE</td>\n")
io.write("    <td colspan=\"", g.max_terminal_symbol, "\">ACTION</td>\n")
io.write("    <td colspan=\"", max_symbol - g.max_terminal_symbol, "\">GOTO</td>\n")
io.write("  </tr>\n")

io.write("  <tr>\n")
for symbol = 1, max_symbol do
  io.write("    <td>", xml.escape(symbols[symbol]), "</td>\n")
end
io.write("  </tr>\n")

for state = 1, max_state do
  io.write("  <tr>\n")
  io.write("    <td>", state, "</td>\n")
  for symbol = 1, max_symbol do
    local index = state * max_symbol + symbol
    if g:is_terminal_symbol(symbol) then
      local action = table[index]
      if action == 0 then
        io.write("    <td></td>\n")
      elseif action <= max_state then
        io.write("    <td>s", action, "</td>\n")
      else
        local reduce = action - max_state
        if reduce == 1 then
          io.write("    <td>acc</td>\n")
        else
          io.write("    <td>r", reduce, "</td>\n")
        end
      end
    else
      local to = table[index]
      if to == 0 then
        io.write("    <td></td>\n")
      else
        io.write("    <td>", to, "</td>\n")
      end
    end
  end
  io.write("  </tr>\n")
end

io.write("</table>\n")
