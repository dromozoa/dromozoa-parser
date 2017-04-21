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
local empty = require "dromozoa.commons.empty"
local hash_table = require "dromozoa.commons.hash_table"
local ipairs = require "dromozoa.commons.ipairs"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local set = require "dromozoa.commons.set"

local class = {}

local epsilon = -1

function class.new(productions, symbols, max_terminal_symbol, start_symbol)
  return {
    productions = productions;
    symbols = symbols;
    max_terminal_symbol = max_terminal_symbol;
    start_symbol = start_symbol;
  }
end

function class:is_terminal_symbol(symbol)
  return symbol ~= nil and 0 < symbol and symbol <= self.max_terminal_symbol
end

function class:is_nonterminal_symbol(symbol)
  return symbol ~= nil and symbol > self.max_terminal_symbol
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

function class:lr0_closure(I)
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

function class:lr0_goto(I, X)
  local productions = self.productions
  local J = sequence()
  for items in I:each() do
    local production = productions[items[1]]
    local dot = items[2]
    local symbol = production[dot]
    if symbol == X then
      J:push(sequence():push(items[1], dot + 1))
    end
  end
  return self:lr0_closure(J)
end

function class:lr0_items()
  local productions = self.productions
  local symbols = self.symbols
  local start_symbol = self.start_symbol
  local C = sequence()
  for id, production in ipairs(productions) do
    if production[1] == start_symbol then
      C:push(self:lr0_closure(sequence():push(sequence():push(id, 2))))
      break
    end
  end
  local added = hash_table()
  local added_C
  repeat
    added_C = false
    for I in C:each() do
      for X in ipairs(symbols) do
        local goto_ = self:lr0_goto(I, X)
        if not empty(goto_) and added:insert(goto_, true) == nil then
          C:push(goto_)
          added_C = true
        end
      end
    end
  until not added_C
  return C
end

function class:first_symbol(X)
  local first = linked_hash_table()
  if self:is_terminal_symbol(X) then
    first:insert(X, true)
    return first
  else
    for production in self.productions:each() do
      if production[1] == X then
        if #production == 1 then
          first:insert(epsilon)
        else
          local have_epsilon
          for i = 2, #production do
            local f = self:first_symbol(production[i])
            have_epsilon = f[epsilon]
            f[epsilon] = nil
            set.union(first, f)
            if not have_epsilon then
              break
            end
          end
          if have_epsilon then
            first:insert(epsilon)
          end
        end
      end
    end
    return first
  end
end

function class:first_symbols(symbols)
  local first = linked_hash_table()
  for symbol in symbols:each() do
    local f = self:first_symbol(symbol)
    local have_epsilon = f[epsilon]
    f[epsilon] = nil
    set_union(first, f)
    if not have_epsilon then
      return first
    end
  end
  first[epsilon] = true
  return first
end

function class:lr1_closure(I)
  local productions = self.productions
  local added = {}
  local added_I
  repeat
    added_I = false
    for items in I:each() do
      local production = productions[items[1]]
      local dot = items[2]
      local a = items[3]
    end
  until not added_I
  return I
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, start_symbol, max_terminal_symbol, productions, symbols)
    return setmetatable(class.new(start_symbol, max_terminal_symbol, productions, symbols), class.metatable)
  end;
})
