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
local unpack = require "dromozoa.commons.unpack"

local class = {}

local epsilon = -1
local eof = 0
local lookahead = -2

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

function class:symbol_name(symbol)
  return self.symbols[symbol]
end

function class:create_nonterminal_symbol(name)
  local symbols = self.symbols
  symbols:push(name)
  return #symbols
end

function class:create_production(head, ...)
  local body = sequence():push(...)
  self.productions:push({ head = head, body = body })
  return self
end

function class:argument()
  local start_symbol = self.start_symbol
  local new_start_symbol = self:create_nonterminal_symbol(self:symbol_name(start_symbol) .. "'")
  self:create_production(new_start_symbol, start_symbol)
  self.start_symbol = new_start_symbol
  self.argumented = true
  return self
end

function class:set_of_items()
  local set_of_items = sequence()
  for id, production in ipairs(self.productions) do
    for i = 1, #production.body + 1 do
      set_of_items:push(sequence():push(id, i))
    end
  end
  return set_of_items
end

function class:each_production(head)
  return coroutine.wrap(function ()
    for id, production in ipairs(self.productions) do
      if production.head == head then
        coroutine.yield(id, production)
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
      local production = productions[item.id]
      local symbol = production.body[item.dot]
      if self:is_nonterminal_symbol(symbol) then
        if not added[symbol] then
          for id in self:each_production(symbol) do
            items:push({ id = id, dot = 1 })
            done = false
          end
          added[symbol] = true
        end
      end
    end
  until done
  return items
end

function class:lr0_goto(items, goto_symbol)
  local productions = self.productions
  local result = sequence()
  for item in items:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    if symbol == goto_symbol then
      result:push({ id = id, dot = dot + 1 })
    end
  end
  return self:lr0_closure(result)
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
    set.union(first, f)
    if not have_epsilon then
      return first
    end
  end
  first[epsilon] = true
  return first
end

function class:lr1_closure(I)
  local productions = self.productions
  local added = hash_table()
  local added_I
  repeat
    added_I = false
    for items in I:each() do
      local production = productions[items[1]]
      local dot = items[2]
      local symbol = production[dot]
      local a = items[3]
      if self:is_nonterminal_symbol(symbol) then
        local symbols = sequence():push(unpack(production, dot + 1)):push(a)
        for id, B in ipairs(productions) do
          if B[1] == symbol then
            local f = self:first_symbols(symbols)
            for b in f:each() do
              local item = sequence():push(id, 2, b)
              if added:insert(item) == nil then
                I:push(item)
                added_I = true
              end
            end
          end
        end
      end
    end
  until not added_I
  return I
end

function class:lr1_goto(I, X)
  local productions = self.productions
  local J = sequence()
  for item in I:each() do
    local id = item[1]
    local production = productions[id]
    local dot = item[2]
    local symbol = production[dot]
    local a = item[3]
    if symbol == X then
      J:push(sequence():push(id, dot + 1, a))
    end
  end
  return self:lr1_closure(J)
end

function class:lr1_items() -- not used LALR(1)
  local productions = self.productions
  local symbols = self.symbols
  local start_symbol = self.start_symbol
  local C = sequence()
  for id, production in ipairs(productions) do
    if production[1] == start_symbol then
      C:push(self:lr1_closure(sequence():push(sequence():push(id, 2, eof))))
      break
    end
  end
  local added = hash_table()
  local added_C
  repeat
    added_C = false
    for I in C:each() do
      for X in ipairs(symbols) do
        local goto_ = self:lr1_goto(I, X)
        if not empty(goto_) and added:insert(goto_, true) == nil then
          C:push(goto_)
          added_C = true
        end
      end
    end
  until not added_C
  return C
end

function class:is_kernel_item(item)
  local id = item[1]
  local production = self.productions[id]
  local dot = item[2]
  return production[1] == self.start_symbol or dot > 2
end

function class:lalr1_kernels(f)
  local productions = self.productions
  local start_symbol = self.start_symbol
  local set_of_items = self:lr0_items()
  local kernels = sequence()

  for items in set_of_items:each() do
    local K = sequence()
    for item in items:each() do
      if self:is_kernel_item(item) then
        K:push(item)
      end
    end
    kernels:push(K)
  end

  local lookaheads = sequence()
  local generated = sequence()

  for i, K in ipairs(kernels) do
    io.write(("======== I_%d ==========\n"):format(i))
    f(self, K)
    -- print("................")
    for item in K:each() do
      local id = item[1]
      local dot = item[2]
      local J = self:lr1_closure(sequence():push(sequence():push(id, dot, lookahead)))
      -- f(self, J)
      for item2 in J:each() do
        local id = item2[1]
        local production = productions[id]
        local dot = item2[2]
        local symbol = production[dot]
        if symbol ~= nil then
          -- print("----------------")
          local goto_ = self:lr1_goto(sequence():push(sequence():push(id, dot, item2[3])), symbol)
          local goto2 = sequence()
          for item3 in goto_:each() do
            if self:is_kernel_item(item3) then
              goto2:push(sequence():push(item3[1], item3[2]))
            end
          end
          -- f(self, goto2)
          if item2[3] == lookahead then
            print("_____ from/to _____")
            f(self, sequence():push(item))
            f(self, goto2)
            -- [TODO] 自分自身へのGOTOが存在する？
            lookaheads:push({
              from = item;
              to = goto2;
            })
          else
            generated:push({
              to = goto2;
              symbol = item2[3];
            })
          end
        end
      end
    end
  end

  print(("/"):rep(80))
  for i, K in ipairs(kernels) do
    io.write(("======== I_%d ==========\n"):format(i))
    for item in K:each() do
      if productions[item[1]][1] == start_symbol and item[2] == 2 then
        item:push(eof)
      end
      for x in generated:each() do
        for y in x.to:each() do
          if item[1] == y[1] and item[2] == y[2] then
            local found = false
            for j = 3, #item do
              if item[j] == x.symbol then
                found = true
              end
            end
            if not found then
              item:push(x.symbol)
            end
          end
        end
      end
    end
    f(self, K)
  end

  for x in lookaheads:each() do
    print("================")
    for y in x.to:each() do
      print("_____ from/to _____")
      f(self, sequence():push(x.from))
      f(self, sequence():push(y))
    end
  end

  repeat
    local not_propagated = true
    print(("/"):rep(80))
    for i, K in ipairs(kernels) do
      io.write(("======== I_%d ==========\n"):format(i))
      for item in K:each() do
        for x in lookaheads:each() do
          for y in x.to:each() do
            if item[1] == y[1] and item[2] == y[2] then
              for K2 in kernels:each() do
                for item2 in K2:each() do
                  if item2[1] == x.from[1] and item2[2] == x.from[2] then
                    -- print("=>")
                    -- f(self, sequence():push(item2, item, x.from, y))
                    -- print("???")
                    -- f(self, x.to)
                    for k = 3, #item2 do
                      local found = false
                      for j = 3, #item do
                        if item[j] == item2[k] then
                          found = true
                        end
                      end
                      if not found then
                        item:push(item2[k])
                        not_propagated = false
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      f(self, K)
    end
  until not_propagated
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, start_symbol, max_terminal_symbol, productions, symbols)
    return setmetatable(class.new(start_symbol, max_terminal_symbol, productions, symbols), class.metatable)
  end;
})
