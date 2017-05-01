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
local keys = require "dromozoa.commons.keys"
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

function class:each_production(head)
  return coroutine.wrap(function ()
    for id, production in ipairs(self.productions) do
      if production.head == head then
        coroutine.yield(id, production.body)
      end
    end
  end)
end

function class:start_production()
  for id, body in self:each_production(self.start_symbol) do
    return id, body
  end
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
  local start_items = sequence():push({ id = self:start_production(), dot = 1 })
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
          transitions:insert({ from = i, to = j, symbol = symbol })
        end
      end
    end
  until done
  return keys(set_of_items), keys(transitions)
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

function class:lr1_items() -- [TODO] not used LALR(1)
  local symbols = self.symbols

  local set_of_items = linked_hash_table()
  local transitions = linked_hash_table()
  local start_items = sequence():push({ id = self:start_production(), dot = 1, la = eof })
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
          transitions:insert({ from = i, to = j, symbol = symbol })
        end
      end
    end
  until done
  return keys(set_of_items), keys(transitions)
end

function class:is_kernel_item(item)
  local id = item.id
  local production = self.productions[id]
  local dot = item.dot
  return production.head == self.start_symbol or dot > 1
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
          local goto_ = self:lr1_goto_(sequence():push(sequence():push(id, dot, item2[3])), symbol)
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
            -- 自分自身へのGOTOは正常
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
                        item:push(item3[k])
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

function class:lalr1_kernels(f)
  local productions = self.productions

  local lr0_set_of_items = self:lr0_items()

  local propagated = sequence()
  local generated = sequence()

  for i, items in ipairs(lr0_set_of_items) do
    for from_item in items:each() do
      if self:is_kernel_item(from_item) then
        local closure = self:lr1_closure(sequence():push({
          id = from_item.id,
          dot = from_item.dot,
          la = lookahead
        }))
        for item in closure:each() do
          local production = productions[item.id]
          local symbol = production.body[item.dot]
          local la = item.la
          if symbol ~= nil then
            local to_items = self:lr1_goto_(sequence():push(item), symbol)
            for to_item in to_items:each() do
              if self:is_kernel_item(to_item) then
                if la == lookahead then
                  print("---- from/to ----")
                  f(self, sequence():push(from_item, to_item))
                  propagated:push({
                    from = { id = from_item.id, dot = from_item.dot };
                    to = { id = to_item.id, dot = to_item.dot };
                  })
                else
                  generated:push({
                    to = { id = to_item.id, dot = to_item.dot };
                    la = la;
                  })
                end
              end
            end
          end
        end
      end
    end
  end

  local result = sequence()
  local map = hash_table()

  for items in lr0_set_of_items:each() do
    local kernel = sequence()
    for item in items:each() do
      if self:is_kernel_item(item) then
        local new_item = {
          id = item.id;
          dot = item.dot;
          la = linked_hash_table();
        }
        kernel:push(new_item)
        map[item] = new_item
      end
    end
    if not empty(kernel) then
      result:push(kernel)
    end
  end

  for id in self:each_production(self.start_symbol) do
    assert(assert(map[{ id = id, dot = 1 }]).la:insert(eof) == nil)
  end

  for op in generated:each() do
    assert(assert(map[op.to]).la:insert(op.la) == nil)
  end

  repeat
    print(("="):rep(80))
    local done = true
    for op in propagated:each() do
      local from_item = assert(map[op.from])
      local to_item = assert(map[op.to])
      print("---- from/to ----")
      f(self, sequence():push(from_item, to_item))
      if set.union(to_item.la, from_item.la) > 0 then
        done = false
      end
    end
  until done

  return result
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, start_symbol, max_terminal_symbol, productions, symbols)
    return setmetatable(class.new(start_symbol, max_terminal_symbol, productions, symbols), class.metatable)
  end;
})
