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
local dumper = require "dromozoa.commons.dumper"
local empty = require "dromozoa.commons.empty"
local hash_table = require "dromozoa.commons.hash_table"
local ipairs = require "dromozoa.commons.ipairs"
local keys = require "dromozoa.commons.keys"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local set = require "dromozoa.commons.set"
local writer = require "dromozoa.parser.writer"

local epsilon = 0
local marker_end = 1
local marker_la = -1

local function equal(items1, items2)
  local n = #items1
  if n ~= #items2 then
    return false
  end
  for i = 1, n do
    local item1 = items1[i]
    local item2 = items2[i]
    if item1.id ~= item2.id then
      return false
    end
    if item1.dot ~= item2.dot then
      return false
    end
    if item1.la ~= item2.la then
      return false
    end
  end
  return true
end

local class = {}

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
  return symbol >= self.min_nonterminal_symbol
end

function class:eliminate_left_recursion()
  local max_terminal_symbol = self.max_terminal_symbol
  local min_nonterminal_symbol = self.min_nonterminal_symbol
  local max_nonterminal_symbol = self.max_nonterminal_symbol

  local map_of_productions = {}
  local n = max_nonterminal_symbol

  for i = min_nonterminal_symbol, max_nonterminal_symbol do
    local left_recursions = {}
    local no_left_recursions = {}

    for _, body in self:each_production(i) do
      local symbol = body[1]
      if symbol and max_terminal_symbol < symbol and symbol < i then
        local productions = map_of_productions[symbol]
        for j = 1, #productions do
          local src_body = productions[j].body
          local new_body = {}
          for k = 1, #src_body do
            new_body[k] = src_body[k]
          end
          for k = 2, #body do
            new_body[#new_body + 1] = body[k]
          end
          if i == new_body[1] then
            left_recursions[#left_recursions + 1] = { head = i, body = new_body }
          else
            no_left_recursions[#no_left_recursions + 1] = { head = i, body = new_body }
          end
        end
      else
        if i == body[1] then
          left_recursions[#left_recursions + 1] = { head = i, body = body }
        else
          no_left_recursions[#no_left_recursions + 1] = { head = i, body = body }
        end
      end
    end

    if left_recursions[1] then
      n = n + 1

      local productions = {}
      for j = 1, #left_recursions do
        local src_body = left_recursions[j].body
        local new_body = {}
        for k = 2, #src_body do
          new_body[#new_body + 1] = src_body[k]
        end
        new_body[#new_body + 1] = n
        productions[#productions + 1] = { head = n, body = new_body }
      end
      productions[#productions + 1] = { head = n, body = {} }
      map_of_productions[n] = productions

      local productions = {}
      for j = 1, #no_left_recursions do
        local src_body = no_left_recursions[j].body
        local new_body = {}
        for k = 1, #src_body do
          new_body[k] = src_body[k]
        end
        new_body[#new_body + 1] = n
        productions[#productions + 1] = { head = i, body = new_body }
      end
      map_of_productions[i] = productions
    else
      map_of_productions[i] = no_left_recursions
    end
  end

  local new_productions = {}
  for _, productions in pairs(map_of_productions) do
    for i = 1, #productions do
      new_productions[#new_productions + 1] = productions[i]
    end
  end

  return class({
    productions = new_productions;
    max_terminal_symbol = max_terminal_symbol;
    max_nonterminal_symbol = n;
    symbol_precedences = self.symbol_precedences;
    production_precedences = self.production_precedences;
  })
end

function class:first_symbol(symbol)
  if symbol <= self.max_terminal_symbol then
    return { [symbol] = true }
  else
    local first_table = self.first_table
    if first_table then
      local first = first_table[symbol]
      if not first then
        error(("first not defined at symbol %d"):format(symbol))
      end
      return first
    else
      local first = {}
      for _, body in self:each_production(symbol) do
        if empty(body) then
          first[epsilon] = true
        else
          for symbol in pairs(self:first_symbols(body)) do
            first[symbol] = true
          end
        end
      end
      return first
    end
  end
end

function class:first_symbols(symbols)
  local first = {}
  for i = 1, #symbols do
    local symbol = symbols[i]
    for symbol in pairs(self:first_symbol(symbol)) do
      first[symbol] = true
    end
    if first[epsilon] then
      first[epsilon] = nil
    else
      return first
    end
  end
  first[epsilon] = true
  return first
end

function class:first()
  local first_table = {}
  for symbol = self.min_nonterminal_symbol, self.max_nonterminal_symbol do
    first_table[symbol] = self:first_symbol(symbol)
  end
  return first_table
end

function class:symbol_precedence(symbol)
  local item = self.symbol_precedences[symbol]
  if item == nil then
    return 0, false -- [TODO] fix 2nd
  else
    return item.precedence, item.associativity
  end
end

function class:production_precedence(id)
  local item = self.production_precedences[id]
  if item then
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
  return 0, false -- [TODO] fix 2nd
end

function class:lr0_closure(items)
  local productions = self.productions
  local max_terminal_symbol = self.max_terminal_symbol
  local added_table = {}
  repeat
    local done = true
    for i = 1, #items do
      local item = items[i]
      local symbol = productions[item.id].body[item.dot]
      if symbol and max_terminal_symbol < symbol and not added_table[symbol] then
        for id in self:each_production(symbol) do
          items[#items + 1] = { id = id, dot = 1 }
          done = false
        end
        added_table[symbol] = true
      end
    end
  until done
end

function class:lr0_goto(items)
  local productions = self.productions
  local gotos = {}
  for i = 1, #items do
    local item = items[i]
    local id = item.id
    local dot = item.dot
    local symbol = productions[id].body[dot]
    if symbol then
      local to_items = gotos[symbol]
      if to_items then
        to_items[#to_items + 1] = { id = id, dot = dot + 1 }
      else
        gotos[symbol] = { { id = id, dot = dot + 1 } }
      end
    end
  end
  for _, to_items in pairs(gotos) do
    self:lr0_closure(to_items)
  end
  return gotos
end

function class:lr0_items()
  local start_items = { { id = 1, dot = 1 } }
  self:lr0_closure(start_items)
  local set_of_items = { start_items }
  local transitions = {}
  repeat
    local done = true
    for i = 1, #set_of_items do
      for symbol, to_items in pairs(self:lr0_goto(set_of_items[i])) do
        if to_items[1] then
          local to
          for j = 1, #set_of_items do
            if equal(to_items, set_of_items[j]) then
              to = j
              break
            end
          end
          if not to then
            to = #set_of_items + 1
            set_of_items[to] = to_items
            done = false
          end
          local transition = transitions[i]
          if transition then
            transition[symbol] = to
          else
            transitions[i] = { [symbol] = to }
          end
        end
      end
    end
  until done
  return set_of_items, transitions
end

function class:lr1_closure(items)
  local productions = self.productions
  local max_terminal_symbol = self.max_terminal_symbol
  local added_table = {}
  repeat
    local done = true
    for i = 1, #items do
      local item = items[i]
      local body = productions[item.id].body
      local dot = item.dot
      local symbol = body[dot]
      if symbol and max_terminal_symbol < symbol then
        local symbols = {}
        for i = dot + 1, #body do
          symbols[#symbols + 1] = body[i]
        end
        symbols[#symbols + 1] = item.la
        local first = self:first_symbols(symbols)
        for id in self:each_production(symbol) do
          local added = added_table[id]
          if not added then
            added = {}
            added_table[id] = added
          end
          for la in pairs(first) do
            if not added[la] then
              items[#items + 1] = { id = id, dot = 1, la = la }
              done = false
              added[la] = true
            end
          end
        end
      end
    end
  until done
end

function class:lr1_goto(items)
  local productions = self.productions
  local gotos = {}
  for i = 1, #items do
    local item = items[i]
    local id = item.id
    local dot = item.dot
    local symbol = productions[id].body[dot]
    if symbol then
      local to_items = gotos[symbol]
      if to_items then
        to_items[#to_items + 1] = { id = id, dot = dot + 1, la = item.la }
      else
        gotos[symbol] = { { id = id, dot = dot + 1, la = item.la } }
      end
    end
  end
  for _, to_items in pairs(gotos) do
    self:lr1_closure(to_items)
  end
  return gotos
end

function class:lr1_items()
  local start_items = { { id = 1, dot = 1, la = 1 } }
  self:lr1_closure(start_items)
  local set_of_items = { start_items }
  local transitions = {}
  repeat
    local done = true
    for i = 1, #set_of_items do
      for symbol, to_items in pairs(self:lr1_goto(set_of_items[i])) do
        if to_items[1] then
          local to
          for j = 1, #set_of_items do
            if equal(to_items, set_of_items[j]) then
              to = j
              break
            end
          end
          if not to then
            to = #set_of_items + 1
            set_of_items[to] = to_items
            done = false
          end
          local transition = transitions[i]
          if transition then
            transition[symbol] = to
          else
            transitions[i] = { [symbol] = to }
          end
        end
      end
    end
  until done
  return set_of_items, transitions
end

function class:lalr1_kernels(set_of_items, transitions)
  local productions = self.productions
  local min_nonterminal_symbol = self.min_nonterminal_symbol

  local set_of_kernel_items = {}
  local map_of_kernel_items = {} -- i,id,dot => j

  for i = 1, #set_of_items do
    local items = set_of_items[i]
    local kernel_items = {}
    local kernel_table = {}
    for j = 1, #items do
      local item = items[j]
      local id = item.id
      local dot = item.dot
      if id == 1 or dot > 1 then
        local map = kernel_table[id]
        if map then
          map[dot] = j
        else
          kernel_table[id] = { [dot] = j }
        end
        if id == 1 and dot == 1 then
          kernel_items[#kernel_items + 1] = { id = id, dot = dot, la = { [1] = true }}
        else
          la = {}
          kernel_items[#kernel_items + 1] = { id = id, dot = dot, la = {} }
        end
      end
    end
    set_of_kernel_items[i] = kernel_items
    map_of_kernel_items[i] = kernel_table
  end

  local propagated = {}

  for i = 1, #set_of_items do
    local from_items = set_of_items[i]
    for j = 1, #from_items do
      local from_item = from_items[j]
      local from_id = from_item.id
      local from_dot = from_item.dot
      if productions[from_id].head == min_nonterminal_symbol or from_dot > 1 then
        local items = { { id = from_id, dot = from_dot, la = marker_la } }
        self:lr1_closure(items)
        for k = 1, #items do
          local item = items[k]
          local id = item.id
          local production = productions[id]
          local dot = item.dot
          local symbol = production.body[dot]
          local la = item.la
          if symbol ~= nil then
            local to_i = transitions[i][symbol]
            local to_j = map_of_kernel_items[to_i][id][dot + 1]
            if la == marker_la then
              propagated[#propagated + 1] = { from_i = i, from_j = j, to_i = to_i, to_j = to_j }
            else
              set_of_kernel_items[to_i][to_j].la[la] = true
            end
          end
        end
      end
    end
  end

  repeat
    local done = true
    for i = 1, #propagated do
      local op = propagated[i]
      local from_la = set_of_kernel_items[op.from_i][op.from_j].la
      local to_la = set_of_kernel_items[op.to_i][op.to_j].la
      for la in pairs(from_la) do
        if not to_la[la] then
          to_la[la] = true
          done = false
        end
      end
    end
  until done

  local expanded_set_of_kernel_items = {}
  for i = 1, #set_of_kernel_items do
    local items = set_of_kernel_items[i]
    local expanded_items = {}
    for j = 1, #items do
      local item = items[j]
      local id = item.id
      local dot = item.dot
      for la in pairs(item.la) do
        expanded_items[#expanded_items + 1] = { id = id, dot = dot, la = la }
      end
    end
    expanded_set_of_kernel_items[#expanded_set_of_kernel_items + 1] = expanded_items
  end

  return expanded_set_of_kernel_items
end

function class:lalr1_items()
  local set_of_items, transitions = self:lr0_items()
  local set_of_items = self:lalr1_kernels(set_of_items, transitions)
  for i = 1, #set_of_items do
    self:lr1_closure(set_of_items[i])
  end
  return set_of_items, transitions
end

function class:lr1_construct_table(set_of_items, transitions)
  local productions = self.productions

  local max_state = #set_of_items
  local max_symbol = self.max_nonterminal_symbol

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

local metatable = {
  __index = class;
}
class.metatable = metatable

return setmetatable(class, {
  __call = function (_, data)
    local max_terminal_symbol = data.max_terminal_symbol
    return setmetatable({
      productions = data.productions;
      max_terminal_symbol = max_terminal_symbol;
      min_nonterminal_symbol = max_terminal_symbol + 1;
      max_nonterminal_symbol = data.max_nonterminal_symbol;
      symbol_precedences = data.symbol_precedences;
      production_precedences = data.production_precedences;
    }, metatable)
  end;
})
