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
local sequence_writer = require "dromozoa.commons.sequence_writer"
local xml = require "dromozoa.commons.xml"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local LOOKAHEAD = "#"

local class = {}

function class.la(out, g, la)
  local symbols = g.symbols
  out:write(symbols[la])
end

function class.production(out, g, production)
  local symbols = g.symbols
  out:write(symbols[production.head], " ", TO)
  for symbol in production.body:each() do
    out:write(" ", symbols[symbol])
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

function class.write_graph(filename, g, set_of_items, transitions)
  local symbols = g.symbols

  local out = assert(io.open(filename, "w"))
  out:write([[
digraph g {
graph [rankdir=LR];
node [shape=plaintext]
]])

  for i, items in ipairs(set_of_items) do
    out:write(("%d [label=<<table border=\"1\" cellborder=\"0\" cellpadding=\"0\" cellspacing=\"0\" margin=\"0\">"):format(i))
    out:write(("<tr><td>I%d</td></tr>"):format(i))
    for item in items:each() do
      out:write(("<tr><td align=\"left\" bgcolor=\"%s\">%s</td></tr>"):format(
          g:is_kernel_item(item) and "white" or "grey",
          xml.escape(class.item(sequence_writer(), g, item):concat())))
    end
    out:write("</table>>]\n")
  end

  for transition, to in transitions:each() do
    out:write(([[
%d->%d [label=<%s>];
]]):format(transition.from, to, xml.escape(symbols[transition.symbol])))
  end

  out:write("}\n")
  out:close()
end

return class
