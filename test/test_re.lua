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

local builder = require "dromozoa.parser.builder"
local regexp = require "dromozoa.parser.regexp"

local regexp_lexer = require "dromozoa.parser.lexers.regexp_lexer"
local regexp_parser = require "dromozoa.parser.parsers.regexp_parser"
local driver = require "dromozoa.parser.driver"

local atom = builder.atom

local P = builder.pattern
local R = builder.range
local S = builder.set

local digit = R"09"
local space = S" \f\n\r\t\v"
local word = R"09AZaz" + "_"

local character_classes = {
  ["\\d"] = digit;
  ["\\s"] = space;
  ["\\w"] = word;
  ["\\D"] = -digit;
  ["\\S"] = -space;
  ["\\W"] = -word;
}

local source = arg[1] or [[\/\*.*?\*\/]]
local parser = regexp_parser()
local root = driver(regexp_lexer(), parser)(source)

local symbol_table = parser.symbol_table
local max_terminal_symbol = parser.max_terminal_symbol

local stack1 = { root }
local stack2 = {}
while true do
  local n1 = #stack1
  local n2 = #stack2
  local node = stack1[n1]
  if not node then
    break
  end
  if node == stack2[n2] then
    stack1[n1] = nil
    stack2[n2] = nil
    local symbol = node[0]
    if symbol == symbol_table.Pattern then
      node.value = node[1].value
    elseif symbol == symbol_table.Disjunction then
      local n = node.n
      if n == 1 then
        local a = node[1]
        node.value = a.value
      elseif n == 3 then
        local a = node[1]
        local b = node[3]
        if a.value and b.value then
          node.value = a.value + b.value
        elseif a.value then
          node.value = a.value
        elseif b.value then
          node.value = b.value
        end
      end
    elseif symbol == symbol_table.Alternative then
      local n = node.n
      if n == 2 then
        local a = node[1]
        local b = node[2]
        if a.value then
          print(a.value, b.value)
          node.value = a.value * b.value
        else
          node.value = b.value
        end
      end
    elseif symbol == symbol_table.Term then
      local n = node.n
      if n == 1 then
        node.value = node[1].value
      elseif n == 2 then
        node.value = node[1].value ^ node[2].value
      end
    elseif symbol == symbol_table.Quantifier then
      node.value = node[1].value
    elseif symbol == symbol_table.QuantifierPrefix then
      local n = node.n
      if n == 3 then
        node.value = { tonumber(node[2].value, 10) }
      elseif n == 4 then
        node.value = tonumber(node[2].value, 10)
      elseif n == 5 then
        node.value = { tonumber(node[2].value, 10), tonumber(node[4].value, 10) }
      else
        node.value = node[1].value
      end
    elseif symbol == symbol_table.Atom then
      local n = node.n
      if n == 1 then
        local a = node[1]
        local a_symbol = a[0]
        if a_symbol == symbol_table["."] then
          node.value = atom.any()
        elseif a_symbol == symbol_table.CharacterClassEscape then
          node.value = character_classes[a.value]:clone()
        elseif a_symbol == symbol_table.CharacterClass then
          node.value = a.value
        else
          local set = { [a.value:byte()] = true }
          node.value = atom(set)
        end
      else
        local b = node[2]
        node.value = b.value
      end
    elseif symbol == symbol_table.CharacterClass then
      local a = node[1]
      local b = node[2]
      if a[0] == symbol_table["[^"] then
        node.value = -atom(b.value)
      else
        node.value = atom(b.value)
      end
    elseif symbol == symbol_table.ClassRanges then
      local n = node.n
      if n == 0 then
        node.value = {}
      else
        local a = node[1]
        node.value = a.value
      end
    elseif symbol == symbol_table.NonemptyClassRanges or symbol == symbol_table.NonemptyClassRangesNoDash then
      local n = node.n
      local a = node[1]
      if n == 1 then
        node.value = { [a.value:byte()] = true }
      elseif n == 2 then
        local b = node[2]
        local set = { [a.value:byte()] = true }
        for byte in pairs(b.value) do
          set[byte] = true
        end
        node.value = set
      else -- n == 4 then
        local c = node[3]
        local d = node[4]
        local set = {}
        for byte = a.value:byte(), c.value:byte() do
          set[byte] = true
        end
        for byte in pairs(d.value) do
          set[byte] = true
        end
        node.value = set
      end
    end
    if node.rs then
      print(("%s %q"):format(parser.symbol_names[symbol], node.rs:sub(node.ri, node.rj)))
    else
      print(("%s"):format(parser.symbol_names[symbol]))
    end
  else
    local n = node.n
    for i = n, 1, -1 do
      if node[i][0] > max_terminal_symbol then
        stack1[#stack1 + 1] = node[i]
      end
    end
    stack2[n2 + 1] = node
  end
end

parser:write_graphviz("test.dot", root)

-- print(dumper.encode(root.value, { pretty = true, stable = true }))

regexp(root.value):nfa_to_dfa():minimize():write_graphviz("test-dfa.dot")
