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
    out:write("\n")
  end
end

function class.set_of_items(out, g, set_of_items)
  for i, items in ipairs(set_of_items) do
    out:write("======== I_", i, " ==========\n")
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

function class.write_table(filename, g, data)
  local max_state = data.max_state
  local max_symbol = data.max_symbol
  local table = data.table
  local symbols = g.symbols

  local out = assert(io.open(filename, "w"))

  out:write([[
  <style>
    td {
      border: 1px solid #ccc;
    }
  </style>
  <table>
  ]])

  out:write("  <tr>\n")
  out:write("    <td rowspan=\"2\">STATE</td>\n")
  out:write("    <td colspan=\"", g.max_terminal_symbol, "\">ACTION</td>\n")
  out:write("    <td colspan=\"", max_symbol - g.max_terminal_symbol, "\">GOTO</td>\n")
  out:write("  </tr>\n")

  out:write("  <tr>\n")
  for symbol = 1, max_symbol do
    out:write("    <td>", xml.escape(symbols[symbol]), "</td>\n")
  end
  out:write("  </tr>\n")

  for state = 1, max_state do
    out:write("  <tr>\n")
    out:write("    <td>", state, "</td>\n")
    for symbol = 1, max_symbol do
      local index = state * max_symbol + symbol
      if g:is_terminal_symbol(symbol) then
        local action = table[index]
        if action == 0 then
          out:write("    <td></td>\n")
        elseif action <= max_state then
          out:write("    <td>s", action, "</td>\n")
        else
          local reduce = action - max_state
          if reduce == 1 then
            out:write("    <td>acc</td>\n")
          else
            out:write("    <td>r", reduce, "</td>\n")
          end
        end
      else
        local to = table[index]
        if to == 0 then
          out:write("    <td></td>\n")
        else
          out:write("    <td>", to, "</td>\n")
        end
      end
    end
    out:write("  </tr>\n")
  end

  out:write("</table>\n")
  out:close()
end

function class.write_tree(filename, g, root)
  local out = assert(io.open(filename, "w"))
  out:write([[
digraph g {
graph [rankdir=TB];
node [shape=plaintext]
]])

  class.write_tree_node(out, g, root, 1)
  class.write_tree_edge(out, g, root)

  out:write("}\n")
  out:close()
end

function class.write_tree(filename, g, t)
  local symbols = g.symbols

  local out = assert(io.open(filename, "w"))
  t:write_graphviz(out, {
    default_node_attributes = function ()
      return {
        shape = "box";
      }
    end;
    node_attributes = function (_, u)
      if u.value then
        return {
          label = "<" .. xml.escape(symbols[u.symbol]) .. " / " .. xml.escape(u.value) .. ">";
        }
      else
        return {
          label = "<" .. xml.escape(symbols[u.symbol]) .. ">";
        }
      end
    end;
  })
  out:close()
end

return class
