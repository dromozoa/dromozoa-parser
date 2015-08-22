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

local sequence_writer

do
  local function write(self, i, j, n, value, ...)
    j = j + 1
    local t = type(value)
    if t == "string" or t == "number" then
      i = i + 1
      self[i] = value
      if j < n then
        return write(self, i, j, n, ...)
      else
        return self
      end
    else
      error("bad argument #" .. j .. " to 'write' (string expected, got " .. t .. ")")
    end
  end

  local class = {}

  function class.new()
    return {}
  end

  function class:write(...)
    return write(self, #self, 0, select("#", ...), ...)
  end

  function class:concat()
    return table.concat(self)
  end

  local metatable = {
    __index = class;
  }

  sequence_writer = function ()
    return setmetatable(class.new(), metatable)
  end
end

local function write_symbol(out, symbol)
  local t = type(symbol)
  if type(symbol) == "table" then
    if #symbol == 0 then
      out:write(EPSILON)
    else
      for v in sequence.each(symbol) do
        out:write(v)
      end
    end
  else
    out:write(symbol)
  end
  return out
end

local function write_symbols(out, symbols)
  local first = true
  for symbol in symbols:each() do
    if first then
      first = false
    else
      out:write(" ")
    end
    write_symbol(out, symbol)
  end
  return out
end

local function write_grammar(out, prods)
  for head, bodies in prods:each() do
    write_symbol(out, head)
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
          write_symbol(out, symbol)
        end
      end
    end
    out:write("\n")
  end
  return out
end

local function write_item(out, item)
  local head, body, dot, term = item[1], item[2], item[3], item[4]
  write_symbol(out, head)
  out:write(" ->")
  for i = 1, #body do
    if dot == i then
      out:write(" ", DOT)
    end
    out:write(" ")
    write_symbol(out, body[i])
  end
  if dot == #body + 1 then
    out:write(" ", DOT)
  end
  if term ~= nil then
    out:write(", ")
    write_symbol(out, term)
  end
  return out
end

local function write_items(out, items, prefix)
  for item in items:each() do
    if prefix ~= nil then
      out:write(prefix)
    end
    write_item(out, item)
    out:write("\n")
  end
  return out
end

local function write_set_of_items(out, set_of_items)
  local i = 0
  for items in set_of_items:each() do
    out:write("I", i, "\n")
    write_items(out, items, "  ")
    i = i + 1
  end
  return out
end

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

function class.unparse_symbols(symbols)
  return write_symbols(sequence_writer(), symbols):concat()
end

function class.unparse_grammar(prods)
  return write_grammar(sequence_writer(), prods):concat()
end

function class.unparse_items(items)
  return write_items(sequence_writer(), items):concat()
end

function class.unparse_set_of_items(set_of_items)
  return write_set_of_items(sequence_writer(), set_of_items):concat()
end

return class
