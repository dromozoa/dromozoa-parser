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
local xml = require "dromozoa.commons.xml"

local TO = string.char(0xE2, 0x86, 0x92) -- U+2192 RIGHWARDS ARROW
local DOT = string.char(0xC2, 0xB7) -- U+00B7 MIDDLE DOT
local LA = "#"

local class = {}

function class.new(symbol_names, productions)
  return {
    symbol_names = symbol_names;
    productions = productions;
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
    self:write(out, item)
    out:write("\n")
  end
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

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, symbol_names, productions)
    return setmetatable(class.new(symbol_names, productions), class.metatable)
  end;
})
