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
local json = require "dromozoa.commons.json"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local xml = require "dromozoa.commons.xml"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local LA = "#"
local EPSILON = string.char(0xCE, 0xB5) -- U+03B5 GREEK SMALL LETTER EPSILON

local class = {}

function class.new(symbol_names, productions, max_terminal_symbol)
  return {
    symbol_names = symbol_names;
    productions = productions;
    max_terminal_symbol = max_terminal_symbol;
  }
end

function class:write_production(out, production)
  local symbol_names = self.symbol_names
  out:write(symbol_names[production.head], " ", TO)
  for symbol in production.body:each() do
    out:write(" ", symbol_names[symbol])
  end
  return out
end

function class:write_item(out, item)
  local symbol_names = self.symbol_names
  local productions = self.productions

  local production = productions[item.id]
  local body = production.body
  local dot = item.dot
  local la = item.la

  out:write(symbol_names[production.head], " ", TO)
  for i, symbol in ipairs(body) do
    if i == dot then
      out:write(" ", DOT)
    end
    out:write(" ", symbol_names[symbol])
  end
  if dot == #body + 1 then
    out:write(" ", DOT)
  end

  if la then
    if type(la) == "number" then
      out:write(", ", symbol_names[la])
    else
      out:write(", ")
      local first = true
      for la in la:each() do
        if first then
          first = false
        else
          out:write(" / ")
        end
        out:write(symbol_names[la])
      end
    end
  end

  return out
end

function class:write_items(out, items)
  for item in items:each() do
    self:write_item(out, item)
    out:write("\n")
  end
  return out
end

function class:write_set_of_items(out, set_of_items)
  for i, items in ipairs(set_of_items) do
    out:write("======== I_", i, " ==========\n")
    self:write_items(out, items)
  end
end

function class:write_first(out, symbols)
  local symbol_names = self.symbol_names
  out:write("{")
  local first = true
  for symbol in symbols:each() do
    if first then
      first = false
    else
      out:write(", ")
    end
    if symbol == 0 then
      out:write(EPSILON)
    else
      out:write(symbol_names[symbol])
    end
  end
  out:write("}")
  return out
end

function class:write_table(out, data)
  local max_state = data.max_state
  local max_symbol = data.max_symbol
  local table = data.table
  local symbol_names = self.symbol_names
  local max_terminal_symbol = self.max_terminal_symbol

  out:write([[
<style>
  table {
    border-collapse: collapse;
  }
  td {
    border: 1px solid #ccc;
    text-align: center;
  }
</style>
<table>
]])
  out:write("  <tr>\n")
  out:write("    <td rowspan=\"2\">STATE</td>\n")
  out:write("    <td colspan=\"", max_terminal_symbol, "\">ACTION</td>\n")
  out:write("    <td colspan=\"", max_symbol - max_terminal_symbol, "\">GOTO</td>\n")
  out:write("  </tr>\n")

  out:write("  <tr>\n")
  for symbol = 1, max_symbol do
    out:write("    <td>", xml.escape(symbol_names[symbol]), "</td>\n")
  end
  out:write("  </tr>\n")

  for state = 1, max_state do
    out:write("  <tr>\n")
    out:write("    <td>", state, "</td>\n")
    for symbol = 1, max_symbol do
      local action = table[state * max_symbol + symbol]
      if action == 0 then
        out:write("    <td></td>\n")
      elseif action <= max_state then
        if symbol <= max_terminal_symbol then
          out:write("    <td>s", action, "</td>\n")
        else
          out:write("    <td>", action, "</td>\n")
        end
      else
        local reduce = action - max_state
        if reduce == 1 then
          out:write("    <td>acc</td>\n")
        else
          out:write("    <td>r", reduce, "</td>\n")
        end
      end
    end
    out:write("  </tr>\n")
  end

  out:write("</table>\n")
  return out
end

function class:write_graph(out, transitions)
  local symbol_names = self.symbol_names
  out:write([[
digraph g {
graph [rankdir=LR];
]])
  for transition, to in transitions:each() do
    out:write(("%d->%d [label=<%s>];\n"):format(transition.from, to, xml.escape(symbol_names[transition.symbol])))
  end
  out:write("}\n")
  return out
end

function class:write_tree(out, tree)
  local symbol_names = self.symbol_names
  tree:write_graphviz(out, {
    default_node_attributes = function ()
      return {
        shape = "box";
      }
    end;
    node_attributes = function (_, u)
      local name = symbol_names[u.symbol]
      local value = u.value
      if value ~= nil and value ~= name then
        return {
          label = "<" .. xml.escape(name) .. " / " .. xml.escape(value) .. ">";
        }
      else
        return {
          label = "<" .. xml.escape(name) .. ">";
        }
      end
    end;
  })
  return out
end

function class:write_conflict(out, conflict, verbose)
  local symbol_names = self.symbol_names
  local productions = self.productions

  if conflict.resolved and not verbose then
    return
  end

  local state = conflict.state
  local symbol = conflict.symbol
  local action = conflict[1].action

  if action == "error" then
    out:write(("error / reduce(%d) conflict resolved as an error"):format(conflict[2].argument))
  elseif action == "shift" then
    out:write(("shift(%d) / reduce(%d) conflict"):format(conflict[1].argument, conflict[2].argument))
    local resolution = conflict.resolution
    if resolution == 0 then
      out:write(" resolved as an error")
    elseif resolution == 1 then
      out:write(" resolved as shift")
    elseif resolution == 2 then
      out:write(" resolved as reduce")
    end
    local shift_precedence = conflict[1].precedence
    local precedence = conflict[2].precedence
    local associativity = conflict[2].associativity
    if precedence > 0 then
      if shift_precedence == precedence then
        out:write((": precedence %d == %d associativity %s"):format(shift_precedence, precedence, associativity))
      elseif shift_precedence < precedence then
        out:write((": precedence %d < %d"):format(shift_precedence, precedence))
      else
        out:write((": precedence %d > %d"):format(shift_precedence, precedence))
      end
    end
  elseif action == "reduce" then
    out:write(("reduce(%d) / reduce(%d) conflict"):format(conflict[1].argument, conflict[2].argument))
  end
  out:write((" at state(%d) symbol(%q)\n"):format(state, symbol_names[symbol]))
end

function class:write_conflicts(out, conflicts, verbose)
  for conflict in conflicts:each() do
    self:write_conflict(out, conflict, verbose)
  end
  return out
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, symbol_names, productions, max_terminal_symbol)
    return setmetatable(class.new(symbol_names, productions, max_terminal_symbol), class.metatable)
  end;
})
