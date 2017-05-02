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

local empty = require "dromozoa.commons.empty"
local equal = require "dromozoa.commons.equal"
local hash_table = require "dromozoa.commons.hash_table"
local ipairs = require "dromozoa.commons.ipairs"
local keys = require "dromozoa.commons.keys"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local set = require "dromozoa.commons.set"
local unpack = require "dromozoa.commons.unpack"

local class = {}

local epsilon = 0
local marker_end = 1
local marker_la = -1
local start_id = 1

function class.new(productions, symbols, max_terminal_symbol, start_symbol)
  return {
    productions = productions;
    symbols = symbols;
    max_terminal_symbol = max_terminal_symbol;
    start_symbol = start_symbol;
  }
end

function class:is_terminal_symbol(symbol)
  return symbol ~= nil and symbol <= self.max_terminal_symbol
end

function class:is_nonterminal_symbol(symbol)
  return symbol ~= nil and symbol > self.max_terminal_symbol
end

function class:each_production(head)
  return coroutine.wrap(function ()
    for id, production in ipairs(self.productions) do
      if production.head == head then
        coroutine.yield(id, production.body)
      end
    end
  end)
end

function class:lr0_closure(items)
  local productions = self.productions
  local added = {}
  repeat
    local done = true
    for item in items:each() do
      local symbol = productions[item.id].body[item.dot]
      if self:is_nonterminal_symbol(symbol) and not added[symbol] then
        for id in self:each_production(symbol) do
          items:push({ id = id, dot = 1 })
          done = false
        end
        added[symbol] = true
      end
    end
  until done
end

function class:lr0_goto(items)
  local productions = self.productions
  local map_of_items = linked_hash_table()
  for item in items:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    if symbol ~= nil then
      local items = map_of_items:get(symbol)
      if items == nil then
        items = sequence()
        map_of_items:insert(symbol, items)
      end
      items:push({ id = id, dot = dot + 1 })
    end
  end
  for symbol, items in map_of_items:each() do
    self:lr0_closure(items)
  end
  return map_of_items
end

function class:lr0_items()
  local set_of_items = linked_hash_table()
  local transitions = linked_hash_table()
  local start_items = sequence():push({ id = start_id, dot = 1 })
  self:lr0_closure(start_items)
  set_of_items:insert(start_items, 1)
  local n = 1
  repeat
    local done = true
    for items, i in set_of_items:each() do
      for symbol, to_items in self:lr0_goto(items):each() do
        if not empty(to_items) then
          local j = set_of_items:get(to_items)
          if j == nil then
            n = n + 1
            set_of_items:insert(to_items, n)
            j = n
            done = false
          end
          transitions:insert({ from = i, symbol = symbol }, j)
        end
      end
    end
  until done
  return keys(set_of_items), transitions
end

function class:first_symbol(symbol)
  local first = linked_hash_table()
  if self:is_terminal_symbol(symbol) then
    first:insert(symbol)
  else
    for _, body in self:each_production(symbol) do
      if empty(body) then
        first:insert(epsilon)
      else
        set.union(first, self:first_symbols(body))
      end
    end
  end
  return first
end

function class:first_symbols(symbols)
  local first = linked_hash_table()
  for symbol in symbols:each() do
    set.union(first, self:first_symbol(symbol))
    if first:remove(epsilon) == nil then
      return first
    end
  end
  first:insert(epsilon)
  return first
end

function class:first(symbols)
  return keys(self:first_symbols(symbols))
end

function class:lr1_closure(items)
  local productions = self.productions
  local added = hash_table()
  repeat
    local done = true
    for item in items:each() do
      local body = productions[item.id].body
      local dot = item.dot
      local symbol = body[dot]
      if self:is_nonterminal_symbol(symbol) then
        local symbols = sequence():push(unpack(body, dot + 1)):push(item.la)
        local first = self:first(symbols)
        for id in self:each_production(symbol) do
          for la in first:each() do
            local item = { id = id, dot = 1, la = la }
            if added:insert(item) == nil then
              items:push(item)
              done = false
            end
          end
        end
      end
    end
  until done
end

function class:lr1_goto(items)
  local productions = self.productions
  local map_of_items = linked_hash_table()
  for item in items:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    local la = item.la
    if symbol ~= nil then
      local items = map_of_items:get(symbol)
      if items == nil then
        items = sequence()
        map_of_items:insert(symbol, items)
      end
      items:push({ id = id, dot = dot + 1, la = la })
    end
  end
  for symbol, items in map_of_items:each() do
    self:lr1_closure(items)
  end
  return map_of_items
end

function class:lr1_items()
  local symbols = self.symbols

  local set_of_items = linked_hash_table()
  local transitions = linked_hash_table()
  local start_items = sequence():push({ id = start_id, dot = 1, la = marker_end })
  self:lr1_closure(start_items)
  set_of_items:insert(start_items, 1)
  local n = 1
  repeat
    local done = true
    for items, i in set_of_items:each() do
      for symbol, to_items in self:lr1_goto(items):each() do
        if not empty(to_items) then
          local j = set_of_items:get(to_items)
          if j == nil then
            n = n + 1
            set_of_items:insert(to_items, n)
            j = n
            done = false
          end
          transitions:insert({ from = i, symbol = symbol }, j)
        end
      end
    end
  until done
  return keys(set_of_items), transitions
end

function class:is_kernel_item(item)
  local id = item.id
  local production = self.productions[id]
  local dot = item.dot
  return production.head == self.start_symbol or dot > 1
end

function class:lalr1_kernels(set_of_items, transitions)
  local productions = self.productions

  local map_of_items = hash_table()
  for i, items in ipairs(set_of_items) do
    for j, item in ipairs(items) do
      map_of_items:insert({ i = i, item = item }, j)
    end
  end

  local propagated = sequence()
  local generated = sequence()

  for i, from_items in ipairs(set_of_items) do
    for j, from_item in ipairs(from_items) do
      if self:is_kernel_item(from_item) then
        local items = sequence():push({ id = from_item.id, dot = from_item.dot, la = marker_la })
        self:lr1_closure(items)
        for item in items:each() do
          local id = item.id
          local production = productions[id]
          local dot = item.dot
          local symbol = production.body[dot]
          local la = item.la
          if symbol ~= nil then
            local to_i = assert(transitions:get({ from = i, symbol = symbol }))
            local to_j = assert(map_of_items:get({ i = to_i, item = { id = id, dot = dot + 1 } }))
            if la == marker_la then
              propagated:push({ from_i = i, from_j = j, to_i = to_i, to_j = to_j })
            else
              generated:push({ i = to_i, j = to_j, la = la })
            end
          end
        end
      end
    end
  end

  local set_of_kernel_items = sequence()

  for items in set_of_items:each() do
    local kernel_items = sequence()
    for item in items:each() do
      if self:is_kernel_item(item) then
        local kernel_item = { id = item.id, dot = item.dot, la = linked_hash_table() }
        if productions[item.id].head == self.start_symbol and item.dot == 1 then
          kernel_item.la:insert(marker_end)
        end
        kernel_items:push(kernel_item)
      end
    end
    set_of_kernel_items:push(kernel_items)
  end

  for op in generated:each() do
    set_of_kernel_items[op.i][op.j].la:insert(op.la)
  end

  repeat
    local done = true
    for op in propagated:each() do
      local from_la = set_of_kernel_items[op.from_i][op.from_j].la
      local to_la = set_of_kernel_items[op.to_i][op.to_j].la
      if set.union(to_la, from_la) > 0 then
        done = false
      end
    end
  until done

  local result = sequence()
  for items in set_of_kernel_items:each() do
    local expanded_items = sequence()
    for item in items:each() do
      local id = item.id
      local dot = item.dot
      for la in item.la:each() do
        expanded_items:push({ id = id, dot = dot, la = la })
      end
    end
    result:push(expanded_items)
  end

  return result
end

function class:lr1_construct_table(set_of_items, transitions)
  local productions = self.productions
  local symbols = self.symbols
  local start_symbol = self.start_symbol

  local actions = hash_table()
  local gotos = hash_table()

  for i, items in ipairs(set_of_items) do
    for item in items:each() do
      local id = item.id
      local production = productions[id]
      local dot = item.dot
      local symbol = production.body[dot]
      local la = item.la
      if symbol == nil then
        if production.head == start_symbol and la == marker_end then
          local action = { "accept" }
          local result = actions:insert({ state = i, symbol = la }, action)
          assert(result == nil or equal(result, action))
        else
          local action = { "reduce", id }
          local result = actions:insert({ state = i, symbol = la }, action)
          assert(result == nil or equal(result, action))
        end
      elseif self:is_terminal_symbol(symbol) then
        local j = assert(transitions:get({ from = i, symbol = symbol }))
        local action = { "shift", j }
        local result = actions:insert({ state = i, symbol = symbol }, action)
        assert(result == nil or equal(result, action))
      end
    end
  end

  for transition, to in transitions:each() do
    local symbol = transition.symbol
    if self:is_nonterminal_symbol(symbol) then
      local result = gotos:insert(transition, to)
      assert(result == nil or result == to)
    end
  end

  return actions, gotos
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, start_symbol, max_terminal_symbol, productions, symbols)
    return setmetatable(class.new(start_symbol, max_terminal_symbol, productions, symbols), class.metatable)
  end;
})
