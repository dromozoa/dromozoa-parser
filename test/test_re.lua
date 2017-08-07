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

local builder = require "dromozoa.parser.builder"
local driver = require "dromozoa.parser.driver"
local error_message = require "dromozoa.parser.error_message"
local regexp = require "dromozoa.parser.regexp"
local regexp_lexer = require "dromozoa.parser.lexers.regexp_lexer"
local regexp_parser = require "dromozoa.parser.parsers.regexp_parser"

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

local source = arg[1] or "abc|bbb|abb" -- or [[\/\*.*?\*\/]]
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
      if node.n == 1 then
        node.value = node[1].value
      else
        node.value = node[1].value + node[3].value
      end
    elseif symbol == symbol_table.Alternative then
      if node.n == 1 then
        node.value = node[1].value
      else
        node.value = node[1].value * node[2].value
      end
    elseif symbol == symbol_table.Term then
      if node.n == 1 then
        node.value = node[1].value
      else
        node.value = node[1].value ^ node[2].value
      end
    elseif symbol == symbol_table.Quantifier then
      local n = node.n
      if n == 3 then
        node.value = { tonumber(node[2].value, 10) }
      elseif n == 4 then
        node.value = tonumber(node[2].value, 10)
      elseif n == 5 then
        local m = tonumber(node[2].value, 10)
        local n = tonumber(node[4].value, 10)
        if m > n then
          error(error_message("syntax error", node[1].s, node[1].i, node[1].file))
        end
        node.value = { m, n }
      else
        node.value = node[1].value
      end
    elseif symbol == symbol_table.Atom then
      if node.n == 1 then
        local that = node[1]
        local that_symbol = that[0]
        if that_symbol == symbol_table["."] then
          node.value = P(1)
        elseif that_symbol == symbol_table.CharacterClass or that_symbol == symbol_table.CharacterClassEscape then
          node.value = that.value
        else
          node.value = P(that.value)
        end
      else
        node.value = node[2].value
      end
    elseif symbol == symbol_table.CharacterClassEscape then
      node.value = character_classes[node[1].value]:clone()
    elseif symbol == symbol_table.CharacterClass then
      if node[1][0] == symbol_table["[^"] then
        node.value = -atom(node[2].value)
      else
        node.value = atom(node[2].value)
      end
    elseif symbol == symbol_table.ClassRanges then
      if node.n == 0 then
        node.value = {}
      else
        node.value = node[1].value
      end
    elseif symbol == symbol_table.NonemptyClassRanges or symbol == symbol_table.NonemptyClassRangesNoDash then
      local n = node.n
      local that = node[1]
      if that[0] == symbol_table.CharacterClassEscape then
        if n == 1 then
          node.value = that.value
        elseif n == 2 then
          local set = {}
          for byte in pairs(that.value) do
            set[byte] = true
          end
          for byte in pairs(node[2].value) do
            set[byte] = true
          end
          node.value = set
        else
          local set = { [0x2d] = true }
          for byte in pairs(that.value) do
            set[byte] = true
          end
          local that = node[3]
          if that[0] == symbol_table.CharacterClassEscape then
            for byte in pairs(that.value) do
              set[byte] = true
            end
          else
            set[that.value:byte()] = true
          end
          for byte in pairs(node[4].value) do
            set[byte] = true
          end
          node.value = set
        end
      else
        if n == 1 then
          node.value = { [node[1].value:byte()] = true }
        elseif n == 2 then
          local set = { [node[1].value:byte()] = true }
          for byte in pairs(node[2].value) do
            set[byte] = true
          end
          node.value = set
        else
          local set = {}
          for byte = node[1].value:byte(), node[3].value:byte() do
            set[byte] = true
          end
          for byte in pairs(node[4].value) do
            set[byte] = true
          end
          node.value = set
        end
      end
    end
  else
    for i = node.n, 1, -1 do
      if node[i][0] > max_terminal_symbol then
        stack1[#stack1 + 1] = node[i]
      end
    end
    stack2[n2 + 1] = node
  end
end

parser:write_graphviz("test.dot", root)

regexp(root.value):nfa_to_dfa():minimize():write_graphviz("test-dfa.dot")
