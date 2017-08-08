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

local parser = require "dromozoa.parser.parser"
local write_conflicts = require "dromozoa.parser.grammar.write_conflicts"
local write_graphviz = require "dromozoa.parser.grammar.write_graphviz"
local write_productions = require "dromozoa.parser.grammar.write_productions"
local write_set_of_items = require "dromozoa.parser.grammar.write_set_of_items"
local write_table = require "dromozoa.parser.grammar.write_table"

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

local function construct_map_of_production_ids(productions)
  local map_of_production_ids = {}
  for i = 1, #productions do
    local production = productions[i]
    local head = production.head
    local production_ids = map_of_production_ids[head]
    if production_ids then
      production_ids[#production_ids + 1] = i
    else
      map_of_production_ids[head] = { i }
    end
  end
  return map_of_production_ids
end

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:eliminate_left_recursion()
  local symbol_names = self.symbol_names
  local productions = self.productions
  local map_of_production_ids = self.map_of_production_ids
  local max_terminal_symbol = self.max_terminal_symbol
  local min_nonterminal_symbol = self.min_nonterminal_symbol

  local map_of_productions = {}
  local n = self.max_nonterminal_symbol

  local new_symbol_names = {}
  for i = 1, n do
    new_symbol_names[i] = symbol_names[i]
  end

  for i = min_nonterminal_symbol, n do
    local left_recursions = {}
    local no_left_recursions = {}

    local production_ids = map_of_production_ids[i]
    for j = 1, #production_ids do
      local body = productions[production_ids[j]].body
      local symbol = body[1]
      if symbol and symbol > max_terminal_symbol and symbol < i then
        local productions = map_of_productions[symbol]
        for k = 1, #productions do
          local src_body = productions[k].body
          local new_body = {}
          for l = 1, #src_body do
            new_body[l] = src_body[l]
          end
          for l = 2, #body do
            new_body[#new_body + 1] = body[l]
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
      new_symbol_names[n] = symbol_names[i] .. "'"

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
  for i = min_nonterminal_symbol, n do
    local productions = map_of_productions[i]
    for j = 1, #productions do
      new_productions[#new_productions + 1] = productions[j]
    end
  end

  return class({
    symbol_names = new_symbol_names;
    symbol_table = self.symbol_table;
    productions = new_productions;
    map_of_production_ids = construct_map_of_production_ids(new_productions);
    max_terminal_symbol = max_terminal_symbol;
    min_nonterminal_symbol = max_terminal_symbol + 1;
    max_nonterminal_symbol = n;
    symbol_precedences = self.symbol_precedences;
    production_precedences = self.production_precedences;
    lr1_closure_cache = {};
  })
end

function class:first_symbol(symbol)
  if symbol <= self.max_terminal_symbol then
    return { [symbol] = true }
  else
    local first_table = self.first_table
    if first_table then
      return first_table[symbol]
    else
      local productions = self.productions
      local production_ids = self.map_of_production_ids[symbol]
      local first = {}
      for i = 1, #production_ids do
        local body = productions[production_ids[i]].body
        if body[1] then
          for symbol in pairs(self:first_symbols(body)) do
            first[symbol] = true
          end
        else
          first[0] = true -- epsilon
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
    if first[0] then -- epsilon
      first[0] = nil
    else
      return first
    end
  end
  first[0] = true -- epsilon
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
  if item then
    return item.precedence, item.associativity
  else
    return 0
  end
end

function class:production_precedence(id)
  local item = self.production_precedences[id]
  if item then
    return item.precedence, item.associativity
  end
  local max_terminal_symbol = self.max_terminal_symbol
  local production = self.productions[id]
  local body = production.body
  for i = #body, 1, -1 do
    local symbol = body[i]
    if symbol <= max_terminal_symbol then
      return self:symbol_precedence(symbol)
    end
  end
  return 0
end

function class:lr0_closure(items)
  local productions = self.productions
  local map_of_production_ids = self.map_of_production_ids
  local max_terminal_symbol = self.max_terminal_symbol
  local added_table = {}
  local m = 1
  while true do
    local n = #items
    if m > n then
      break
    end
    for i = m, n do
      local item = items[i]
      local symbol = productions[item.id].body[item.dot]
      if symbol and symbol > max_terminal_symbol and not added_table[symbol] then
        local production_ids = map_of_production_ids[symbol]
        for j = 1, #production_ids do
          items[#items + 1] = { id = production_ids[j], dot = 1 }
        end
        added_table[symbol] = true
      end
    end
    m = n + 1
  end
end

function class:lr0_goto(items)
  local productions = self.productions
  local symbols = {}
  local map_of_to_items = {}
  for i = 1, #items do
    local item = items[i]
    local id = item.id
    local dot = item.dot
    local symbol = productions[id].body[dot]
    if symbol then
      local to_items = map_of_to_items[symbol]
      if to_items then
        to_items[#to_items + 1] = { id = id, dot = dot + 1 }
      else
        symbols[#symbols + 1] = symbol
        map_of_to_items[symbol] = { { id = id, dot = dot + 1 } }
      end
    end
  end
  local gotos = {}
  for i = 1, #symbols do
    local symbol = symbols[i]
    local to_items = map_of_to_items[symbol]
    self:lr0_closure(to_items)
    gotos[#gotos + 1] = {
      symbol = symbol;
      to_items = to_items;
    }
  end
  return gotos
end

function class:lr0_items()
  local start_items = { { id = 1, dot = 1 } }
  self:lr0_closure(start_items)
  local set_of_items = { start_items }
  local transitions = {}
  local m = 1
  while true do
    local n = #set_of_items
    if m > n then
      break
    end
    for i = m, n do
      local transition = transitions[i]
      if not transition then
        transition = {}
        transitions[i] = transition
      end
      local gotos = self:lr0_goto(set_of_items[i])
      for j = 1, #gotos do
        local data = gotos[j]
        local to_items = data.to_items
        if to_items[1] then
          local to
          for k = 1, #set_of_items do
            if equal(to_items, set_of_items[k]) then
              to = k
              break
            end
          end
          if not to then
            to = #set_of_items + 1
            set_of_items[to] = to_items
          end
          transition[data.symbol] = to
        end
      end
    end
    m = n + 1
  end
  return set_of_items, transitions
end

function class:lr1_closure(items)
  local productions = self.productions
  local map_of_production_ids = self.map_of_production_ids
  local max_terminal_symbol = self.max_terminal_symbol
  local lr1_closure_cache = self.lr1_closure_cache
  local first_table = self.first_table
  local added_table = {}
  local m = 1
  while true do
    local n = #items
    if m > n then
      break
    end
    for i = m, n do
      local item = items[i]
      local id = item.id
      local dot = item.dot
      local la = item.la
      local body = productions[id].body
      local symbol = body[dot]
      if symbol and symbol > max_terminal_symbol then
        local cache1 = lr1_closure_cache[id]
        local cache2
        local closure
        if cache1 then
          cache2 = cache1[dot]
          if cache2 then
            closure = cache2[la]
          else
            cache2 = {}
            cache1[dot] = cache2
          end
        else
          cache2 = {}
          cache1 = { [dot] = cache2 }
          lr1_closure_cache[id] = cache1
        end

        if not closure then
          closure = {}
          cache2[la] = closure

          local first = {}
          for j = dot + 1, #body + 1 do
            local symbol = body[j]
            if symbol then
              if symbol <= max_terminal_symbol then
                first[symbol] = true
                break
              else
                for symbol in pairs(first_table[symbol]) do
                  first[symbol] = true
                end
                if first[0] then -- epsilon
                  first[0] = nil
                else
                  break
                end
              end
            else
              first[la] = true
            end
          end

          local production_ids = map_of_production_ids[symbol]
          for j = 1, #production_ids do
            local id = production_ids[j]
            for la in pairs(first) do
              closure[#closure + 1] = { id = id, dot = 1, la = la }
            end
          end
        end

        for j = 1, #closure do
          local item = closure[j]
          local id = item.id
          local la = item.la
          local added = added_table[id]
          if added then
            if not added[la] then
              items[#items + 1] = item
              added[la] = true
            end
          else
            items[#items + 1] = item
            added_table[id] = { [la] = true }
          end
        end
      end
    end
    m = n + 1
  end
end

function class:lr1_goto(items)
  local productions = self.productions
  local symbols = {}
  local map_of_to_items = {}
  for i = 1, #items do
    local item = items[i]
    local id = item.id
    local dot = item.dot
    local symbol = productions[id].body[dot]
    if symbol then
      local to_items = map_of_to_items[symbol]
      if to_items then
        to_items[#to_items + 1] = { id = id, dot = dot + 1, la = item.la }
      else
        symbols[#symbols + 1] = symbol
        map_of_to_items[symbol] = { { id = id, dot = dot + 1, la = item.la } }
      end
    end
  end
  local gotos = {}
  for i = 1, #symbols do
    local symbol = symbols[i]
    local to_items = map_of_to_items[symbol]
    self:lr1_closure(to_items)
    gotos[#gotos + 1] = {
      symbol = symbol;
      to_items = to_items;
    }
  end
  return gotos
end

function class:lr1_items()
  local start_items = { { id = 1, dot = 1, la = 1 } } -- la = marker_end
  self:lr1_closure(start_items)
  local set_of_items = { start_items }
  local transitions = {}
  local m = 1
  while true do
    local n = #set_of_items
    if m > n then
      break
    end
    for i = m, n do
      local transition = transitions[i]
      if not transition then
        transition = {}
        transitions[i] = transition
      end
      local gotos = self:lr1_goto(set_of_items[i])
      for j = 1, #gotos do
        local data = gotos[j]
        local to_items = data.to_items
        if to_items[1] then
          local to
          for k = 1, #set_of_items do
            if equal(to_items, set_of_items[k]) then
              to = k
              break
            end
          end
          if not to then
            to = #set_of_items + 1
            set_of_items[to] = to_items
          end
          transition[data.symbol] = to
        end
      end
    end
    m = n + 1
  end
  return set_of_items, transitions
end

function class:lalr1_kernels(set_of_items, transitions)
  local productions = self.productions
  local min_nonterminal_symbol = self.min_nonterminal_symbol

  local set_of_kernel_items = {}
  local map_of_kernel_items = {}

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
          kernel_items[#kernel_items + 1] = { id = id, dot = dot, la = { true } } -- la = { [marker_end] = true }
        else
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
        local items = { { id = from_id, dot = from_dot, la = -1 } } -- la = marker_lookahead
        self:lr1_closure(items)
        for k = 1, #items do
          local item = items[k]
          local id = item.id
          local production = productions[id]
          local dot = item.dot
          local symbol = production.body[dot]
          if symbol then
            local la = item.la
            local to_i = transitions[i][symbol]
            local to_j = map_of_kernel_items[to_i][id][dot + 1]
            if la == -1 then -- marker_lookahead
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
  local max_terminal_symbol = self.max_terminal_symbol

  local m = #set_of_items
  local n = self.max_nonterminal_symbol
  local actions = {}
  local gotos = {}
  local conflicts = {}

  for i = 1, m do
    local items = set_of_items[i]
    local terminal_symbol_table = {}
    local t = {}
    for j = 1, #items do
      local item = items[j]
      local symbol = productions[item.id].body[item.dot]
      if symbol and symbol <= max_terminal_symbol and not terminal_symbol_table[symbol] then
        t[symbol] = transitions[i][symbol]
        terminal_symbol_table[symbol] = true
      end
    end
    local error_table = {}
    for j = 1, #items do
      local item = items[j]
      local id = item.id
      local symbol = productions[id].body[item.dot]
      if not symbol then
        local action = m + id
        local symbol = item.la
        local value = t[symbol]
        if value then
          local conflict = {
            state = i;
            symbol = symbol;
            resolution = 1; -- shift
          }
          if value <= m then
            local shift_precedence = self:symbol_precedence(symbol)
            local precedence, associativity = self:production_precedence(id)
            conflict[1] = { action = 1, argument = value, precedence = shift_precedence }
            conflict[2] = { action = 2, argument = id, precedence = precedence, associativity = associativity }
            if precedence > 0 then
              conflict.resolved = true
              if shift_precedence == precedence then
                if associativity == 1 then -- left
                  conflict.resolution = 2 -- reduce
                  t[symbol] = action
                elseif associativity == 3 then -- nonassoc
                  conflict.resolution = 3 -- error
                  error_table[symbol] = action
                  t[symbol] = nil
                end
              elseif shift_precedence < precedence then
                conflict.resolution = 2 -- reduce
                t[symbol] = action
              end
            end
          else
            conflict[1] = { action = 2, argument = value - m }
            conflict[2] = { action = 2, argument = id }
            if action < value then
              conflict.resolution = 2 -- reduce
              t[symbol] = action
            end
          end
          conflicts[#conflicts + 1] = conflict
        else
          if error_table[symbol] then
            conflicts[#conflicts + 1] = {
              state = i;
              symbol = symbol;
              { action = 3 };
              { action = 2, argument = id };
            }
          else
            t[symbol] = action
          end
        end
      end
    end
    actions[i] = t
  end

  for i = 1, #transitions do
    local t = {}
    for symbol, to in pairs(transitions[i]) do
      if symbol > max_terminal_symbol then
        local j = symbol - max_terminal_symbol
        t[j] = to
      end
    end
    gotos[i] = t
  end

  local heads = {}
  local sizes = {}
  local reduce_to_semantic_actions = {}
  for i = 2, #productions do
    local production = productions[i]
    local j = m + i
    heads[j] = production.head
    sizes[j] = #production.body
    reduce_to_semantic_actions[j] = production.semantic_actions
  end

  return parser({
    symbol_names = self.symbol_names;
    symbol_table = self.symbol_table;
    max_state = m;
    max_terminal_symbol = max_terminal_symbol;
    max_nonterminal_symbol = n;
    actions = actions;
    gotos = gotos;
    heads = heads;
    sizes = sizes;
    reduce_to_semantic_actions = reduce_to_semantic_actions;
  }), conflicts
end

function class:write_productions(out)
  if type(out) == "string" then
    write_productions(self, assert(io.open(out, "w"))):close()
  else
    return write_productions(self, out)
  end
end

function class:write_set_of_items(out, set_of_items)
  if type(out) == "string" then
    write_set_of_items(self, assert(io.open(out, "w")), set_of_items)
  else
    return write_set_of_items(self, out, set_of_items)
  end
end

function class:write_graphviz(out, set_of_items, transitions)
  if type(out) == "string" then
    write_graphviz(self, assert(io.open(out, "w")), set_of_items, transitions):close()
  else
    return write_graphviz(self, out, set_of_items, transitions)
  end
end

function class:write_table(out, data)
  if type(out) == "string" then
    write_table(self, assert(io.open(out, "w")), data):close()
  else
    return write_table(self, out, data)
  end
end

function class:write_conflicts(out, conflicts, verbose)
  if type(out) == "string" then
    return write_conflicts(self, assert(io.open(out, "w")), conflicts, verbose):close()
  else
    return write_conflicts(self, out, conflicts, verbose)
  end
end

return setmetatable(class, {
  __call = function (_, data)
    local max_terminal_symbol = data.max_terminal_symbol
    local productions = data.productions
    return setmetatable({
      symbol_names = data.symbol_names;
      symbol_table = data.symbol_table;
      productions = productions;
      map_of_production_ids = construct_map_of_production_ids(productions);
      max_terminal_symbol = max_terminal_symbol;
      min_nonterminal_symbol = max_terminal_symbol + 1;
      max_nonterminal_symbol = data.max_nonterminal_symbol;
      symbol_precedences = data.symbol_precedences;
      production_precedences = data.production_precedences;
      lr1_closure_cache = {};
    }, metatable)
  end;
})
