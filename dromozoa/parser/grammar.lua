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
local hash_table = require "dromozoa.commons.hash_table"
local ipairs = require "dromozoa.commons.ipairs"
local keys = require "dromozoa.commons.keys"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local set = require "dromozoa.commons.set"

local epsilon = 0
local marker_end = 1
local marker_la = -1
local start_id = 1

local class = {}

function class.new(productions, max_terminal_symbol, max_nonterminal_symbol, symbol_precedences, production_precedences)
  return {
    productions = productions;
    max_terminal_symbol = max_terminal_symbol;
    max_nonterminal_symbol = max_nonterminal_symbol;
    symbol_precedences = symbol_precedences;
    production_precedences = production_precedences;
  }
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

function class:is_terminal_symbol(symbol)
  return symbol <= self.max_terminal_symbol
end

function class:is_nonterminal_symbol(symbol)
  return symbol > self.max_terminal_symbol
end

function class:is_kernel_item(item)
  return self.productions[item.id].head == self.max_nonterminal_symbol or item.dot > 1
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

function class:symbol_precedence(symbol)
  local item = self.symbol_precedences[symbol]
  if item == nil then
    return 0, false
  else
    return item.precedence, item.associativity
  end
end

function class:production_precedence(id)
  local item = self.production_precedences[id]
  if item ~= nil then
    return item.precedence, item.associativity
  end
  local production = self.productions[id]
  local body = production.body
  for i = #body, 1, -1 do
    local symbol = body[i]
    if self:is_terminal_symbol(symbol) then
      return self:symbol_precedence(symbol)
    end
  end
  return 0, false
end

function class:lr0_closure(items)
  local productions = self.productions
  local added = {}
  repeat
    local done = true
    for item in items:each() do
      local symbol = productions[item.id].body[item.dot]
      if symbol ~= nil and self:is_nonterminal_symbol(symbol) and not added[symbol] then
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
  local gotos = linked_hash_table()
  for item in items:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    if symbol ~= nil then
      local to_items = gotos[symbol]
      if to_items == nil then
        to_items = sequence()
        gotos[symbol] = to_items
      end
      to_items:push({ id = id, dot = dot + 1 })
    end
  end
  for _, to_items in gotos:each() do
    self:lr0_closure(to_items)
  end
  return gotos
end

function class:lr0_items()
  local set_of_items = linked_hash_table()
  local transitions = linked_hash_table()
  local start_items = sequence():push({ id = start_id, dot = 1 })
  self:lr0_closure(start_items)
  set_of_items[start_items] = 1
  local n = 1
  repeat
    local done = true
    for items, i in set_of_items:each() do
      for symbol, to_items in self:lr0_goto(items):each() do
        if not empty(to_items) then
          local j = set_of_items[to_items]
          if j == nil then
            j = n + 1
            n = j
            set_of_items[to_items] = j
            done = false
          end
          transitions[{ from = i, symbol = symbol }] = j
        end
      end
    end
  until done
  return keys(set_of_items), transitions
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
      if symbol ~= nil and self:is_nonterminal_symbol(symbol) then
        local symbols = sequence():copy(body, dot + 1):push(item.la)
        local first = self:first_symbols(symbols)
        for id in self:each_production(symbol) do
          for la in first:each() do
            local item = { id = id, dot = 1, la = la }
            if not added[item] then
              items:push(item)
              done = false
              added[item] = true
            end
          end
        end
      end
    end
  until done
end

function class:lr1_goto(items)
  local productions = self.productions
  local gotos = linked_hash_table()
  for item in items:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    if symbol ~= nil then
      local to_items = gotos:get(symbol)
      if to_items == nil then
        to_items = sequence()
        gotos[symbol] = to_items
      end
      to_items:push({ id = id, dot = dot + 1, la = item.la })
    end
  end
  for _, to_items in gotos:each() do
    self:lr1_closure(to_items)
  end
  return gotos
end

function class:lr1_items()
  local set_of_items = linked_hash_table()
  local transitions = linked_hash_table()
  local start_items = sequence():push({ id = start_id, dot = 1, la = marker_end })
  self:lr1_closure(start_items)
  set_of_items[start_items] = 1
  local n = 1
  repeat
    local done = true
    for items, i in set_of_items:each() do
      for symbol, to_items in self:lr1_goto(items):each() do
        if not empty(to_items) then
          local j = set_of_items[to_items]
          if j == nil then
            j = n + 1
            n = j
            set_of_items[to_items] = j
            done = false
          end
          transitions[{ from = i, symbol = symbol }] = j
        end
      end
    end
  until done
  return keys(set_of_items), transitions
end

function class:lalr1_kernels(set_of_items, transitions)
  local productions = self.productions

  local set_of_kernel_items = sequence()
  local map_of_kernel_items = hash_table()

  for i, items in ipairs(set_of_items) do
    local kernel_items = sequence()
    for j, item in ipairs(items) do
      if self:is_kernel_item(item) then
        map_of_kernel_items[{ i = i, item = item }] = j
        local la = linked_hash_table()
        if item.id == start_id and item.dot == 1 then
          la:insert(marker_end)
        end
        kernel_items:push({ id = item.id, dot = item.dot, la = la })
      end
    end
    set_of_kernel_items:push(kernel_items)
  end

  local propagated = sequence()

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
            local to_i = transitions[{ from = i, symbol = symbol }]
            local to_j = map_of_kernel_items[{ i = to_i, item = { id = id, dot = dot + 1 } }]
            if la == marker_la then
              propagated:push({ from_i = i, from_j = j, to_i = to_i, to_j = to_j })
            else
              set_of_kernel_items[to_i][to_j].la:insert(la)
            end
          end
        end
      end
    end
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

  local expanded_set_of_kernel_items = sequence()
  for items in set_of_kernel_items:each() do
    local expanded_items = sequence()
    for item in items:each() do
      local id = item.id
      local dot = item.dot
      for la in item.la:each() do
        expanded_items:push({ id = id, dot = dot, la = la })
      end
    end
    expanded_set_of_kernel_items:push(expanded_items)
  end

  return expanded_set_of_kernel_items
end

function class:lalr1_items()
  local set_of_items, transitions = self:lr0_items()
  local set_of_items = self:lalr1_kernels(set_of_items, transitions)
  for items in set_of_items:each() do
    self:lr1_closure(items)
  end
  return set_of_items, transitions
end

function class:lr1_construct_table(set_of_items, transitions)
  local productions = self.productions
  local max_nonterminal_symbol = self.max_nonterminal_symbol

  local max_state = #set_of_items
  local max_symbol = max_nonterminal_symbol - 1

  local table = {}
  local conflicts = sequence()

  for i = 1, (max_state + 1) * max_symbol do
    table[i] = 0
  end

  for i, items in ipairs(set_of_items) do
    local terminal_symbol_table = {}
    for item in items:each() do
      local symbol = productions[item.id].body[item.dot]
      if symbol ~= nil and self:is_terminal_symbol(symbol) and not terminal_symbol_table[symbol] then
        terminal_symbol_table[symbol] = true
        table[i * max_symbol + symbol] = transitions[{ from = i, symbol = symbol }]
      end
    end
    local error_table = {}
    for item in items:each() do
      local id = item.id
      local symbol = productions[id].body[item.dot]
      if symbol == nil then
        local action = max_state + id
        local symbol = item.la
        local index = i * max_symbol + symbol
        local current = table[index]
        if current == 0 then
          if error_table[index] then
            conflicts:push({
              state = i;
              symbol = symbol;
              { action = "error" };
              { action = "reduce", argument = id };
            })
          else
            table[index] = action
          end
        else
          local conflict = {
            state = i;
            symbol = symbol;
            resolution = 1;
          }
          if current <= max_state then
            local shift_precedence = self:symbol_precedence(symbol)
            local precedence, associativity = self:production_precedence(id)
            conflict[1] = { action = "shift", argument = current, precedence = shift_precedence }
            conflict[2] = { action = "reduce", argument = id, precedence = precedence, associativity = associativity }
            if precedence > 0 then
              conflict.resolved = true
              if shift_precedence == precedence then
                if associativity == "left" then
                  conflict.resolution = 2
                  table[index] = action
                elseif associativity == "nonassoc" then
                  conflict.resolution = 0
                  error_table[index] = action
                  table[index] = 0
                end
              elseif shift_precedence < precedence then
                conflict.resolution = 2
                table[index] = action
              end
            end
          else
            conflict[1] = { action = "reduce", argument = current - max_state }
            conflict[2] = { action = "reduce", argument = id }
            if action < current then
              conflict.resolution = 2
              table[index] = action
            end
          end
          conflicts:push(conflict)
        end
      end
    end
  end

  for transition, to in transitions:each() do
    local symbol = transition.symbol
    if self:is_nonterminal_symbol(symbol) then
      local index = transition.from * max_symbol + symbol
      local current = table[index]
      table[index] = to
    end
  end

  local heads = {}
  local sizes = {}
  for i = 1, max_state + 1 do
    heads[i] = 0
    sizes[i] = 0
  end
  for i = 2, #productions do
    local production = productions[i]
    local j = max_state + i
    heads[j] = production.head
    sizes[j] = #production.body
  end

  return {
    max_state = max_state;
    max_symbol = max_symbol;
    table = table;
    heads = heads;
    sizes = sizes;
  }, conflicts
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, productions, max_terminal_symbol, max_nonterminal_symbol, symbol_precedences, production_precedences)
    return setmetatable(class.new(productions, max_terminal_symbol, max_nonterminal_symbol, symbol_precedences, production_precedences), class.metatable)
  end;
})
