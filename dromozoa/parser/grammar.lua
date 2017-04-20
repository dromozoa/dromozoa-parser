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

local clone = require "dromozoa.commons.clone"
local ipairs = require "dromozoa.commons.ipairs"
local sequence = require "dromozoa.commons.sequence"

local class = {}

function class.new(productions, symbols, max_terminal_symbol, start_symbol)
  return {
    productions = productions;
    symbols = symbols;
    max_terminal_symbol = max_terminal_symbol;
    start_symbol = start_symbol;
  }
end

function class:is_terminal_symbol(symbol)
  return symbol <= self.max_terminal_symbol
end

function class:is_nonterminal_symbol(symbol)
  return symbol > self.max_terminal_symbol
end

function class:symbol_name(symbol)
  return self.symbols[symbol]
end

function class:create_nonterminal_symbol(name)
  local symbols = self.symbols
  symbols:push(name)
  return #symbols
end

function class:create_production(...)
  self.productions:push(sequence():push(...))
  return self
end

function class:argument()
  local start_symbol = self.start_symbol
  local new_start_symbol = self:create_nonterminal_symbol(self:symbol_name(start_symbol) .. "'")
  self:create_production(new_start_symbol, start_symbol)
  self.start_symbol = new_start_symbol
  return self
end

function class:set_of_items()
  local set_of_items = sequence()
  for id, production in ipairs(self.productions) do
    for i = 1, #production + 1 do
      set_of_items:push(sequence():push(id, i))
    end
  end
  return set_of_items
end

function class:closure(I)
  local productions = self.productions
  local J = clone(I)
  local added = {}
  local added_J
  repeat
    added_J = false
    for items in J:each() do
      local production = productions[items[1]]
      local dot = items[2]
      local symbol = production[dot]
      if self:is_nonterminal_symbol(symbol) then
        if not added[symbol] then
          for id, production in ipairs(productions) do
            if production[1] == symbol then
              J:push(sequence():push(id, 2))
              added_J = true
            end
          end
          added[symbol] = true
        end
      end
    end
  until not added_J
  return J
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, start_symbol, max_terminal_symbol, productions, symbols)
    return setmetatable(class.new(start_symbol, max_terminal_symbol, productions, symbols), class.metatable)
  end;
})
