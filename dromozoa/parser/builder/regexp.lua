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

local driver = require "dromozoa.parser.driver"
local error_message = require "dromozoa.parser.error_message"
local regexp_lexer = require "dromozoa.parser.lexers.regexp_lexer"
local regexp_parser = require "dromozoa.parser.parsers.regexp_parser"
local value = require "dromozoa.parser.value"

local class = {}

function class.parse(s)
  local super = class.super
  local atom = super.atom
  local P = super.pattern
  local R = super.range
  local S = super.set

  local character_classes = class.character_classes
  if not character_classes then
    local digit = R"09"
    local space = S" \f\n\r\t\v"
    local word = R"09AZaz" + "_"
    character_classes = {
      ["\\d"] = digit;
      ["\\s"] = space;
      ["\\w"] = word;
      ["\\D"] = -digit;
      ["\\S"] = -space;
      ["\\W"] = -word;
    }
    class.character_classes = character_classes
  end

  local lexer = regexp_lexer()
  local parser = regexp_parser()
  local root = assert(driver(lexer, parser)(s))

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
        node.value = value(node[1])
      elseif symbol == symbol_table.Disjunction then
        if node.n == 1 then
          node.value = value(node[1])
        else
          node.value = value(node[1]) + value(node[3])
        end
      elseif symbol == symbol_table.Alternative then
        if node.n == 1 then
          node.value = value(node[1])
        else
          node.value = value(node[1]) * value(node[2])
        end
      elseif symbol == symbol_table.Term then
        if node.n == 1 then
          node.value = value(node[1])
        else
          node.value = value(node[1]) ^ value(node[2])
        end
      elseif symbol == symbol_table.Quantifier then
        local n = node.n
        if n == 3 then
          node.value = { tonumber(value(node[2]), 10) }
        elseif n == 4 then
          node.value = tonumber(value(node[2]), 10)
        elseif n == 5 then
          local m = tonumber(value(node[2]), 10)
          local n = tonumber(value(node[4]), 10)
          if m > n then
            error(error_message("syntax error", source, node[1].i))
          end
          node.value = { m, n }
        else
          node.value = value(node[1])
        end
      elseif symbol == symbol_table.Atom then
        if node.n == 1 then
          local that = node[1]
          if that[0] == symbol_table["."] then
            node.value = P(1)
          else
            node.value = P(value(that))
          end
        else
          node.value = value(node[2])
        end
      elseif symbol == symbol_table.CharacterClassEscape then
        node.value = character_classes[value(node[1])]:clone()
      elseif symbol == symbol_table.CharacterClass then
        if node[1][0] == symbol_table["[^"] then
          node.value = -value(node[2])
        else
          node.value = value(node[2])
        end
      elseif symbol == symbol_table.ClassRanges then
        if node.n == 0 then
          node.value = atom({})
        else
          node.value = value(node[1])
        end
      elseif symbol == symbol_table.NonemptyClassRanges or symbol == symbol_table.NonemptyClassRangesNoDash then
        local n = node.n
        if n == 1 then
          node.value = P(value(node[1]))
        elseif n == 2 then
          node.value = P(value(node[1])) + P(value(node[2]))
        else
          local a = value(node[1])
          local b = value(node[3])
          if type(a) == "string" and type(b) == "string" then
            local set = {}
            for byte = a:byte(), b:byte() do
              set[byte] = true
            end
            node.value = atom(set) + P(value(node[4]))
          else
            node.value = P(a) + P"-" + P(b) + P(value(node[4]))
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

  return value(root)
end

return class
