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

local sequence = require "dromozoa.commons.sequence"
local tree = require "dromozoa.tree"

local marker_end = 1
local start_state = 1

local class = {}

function class.new(grammar, data)
  return {
    productions = grammar.productions;
    max_state = data.max_state;
    max_symbol = data.max_symbol;
    table = data.table;
    states = sequence():push(start_state);
    symbols = sequence();
    tree = tree();
  }
end

function class:parse(symbol)
  if symbol == nil then
    symbol = { code = marker_end }
  end

  local productions = self.productions
  local max_state = self.max_state
  local max_symbol = self.max_symbol
  local table = self.table
  local states = self.states
  local symbols = self.symbols

  local state = states:top()
  local action = table[state * max_symbol + symbol.code]
  if action == 0 then
    error("parse error")
  elseif action <= max_state then
    states:push(action)
    symbols:push(symbol)
  else
    local reduce = action - max_state
    if reduce == 1 then
      return symbols:pop()
    else
      local production = productions[reduce]
      local body = sequence()
      local m = #symbols
      local n = #production.body
      for i = 1, n do
        local j = m - n + i
        body[i] = symbols[j]
        symbols[j] = nil
      end
      for i = 1, #production.body do
        states:pop()
      end
      local state = states:top()
      states:push(table[state * max_symbol + production.head])
      symbols:push({ code = production.head, body = body })
      return self:parse(symbol)
    end
  end
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, grammar, data)
    return setmetatable(class.new(grammar, data), class.metatable)
  end;
})
