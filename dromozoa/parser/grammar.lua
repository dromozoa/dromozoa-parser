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
  local added = hash_table()
  repeat
    local done = true
    for item in items:each() do
      local production = productions[item.id]
      local symbol = production.body[item.dot]
      if self:is_nonterminal_symbol(symbol) then
        if not added[symbol] then
          for id in self:each_production(symbol) do
            local item = { id = id, dot = 1 }
            if added:insert(item) == nil then
              items:push(item)
              done = false
            end
          end
        end
      end
    end
  until done
  return items
end

function class:lr0_goto(items, to_symbol)
  local productions = self.productions
  local result = sequence()
  for item in items:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    if symbol == to_symbol then
      result:push({ id = id, dot = dot + 1 })
    end
  end
  return self:lr0_closure(result)
end

function class:lr0_items()
  local symbols = self.symbols
  local result = sequence()
  for id in self:each_production(self.start_symbol) do
    result:push(self:lr0_closure(sequence():push({ id = id, dot = 1 })))
  end
  local added = hash_table()
  repeat
    local done = true
    for items in result:each() do
      -- [TODO] 全部のシンボルについて試す必要はない
      for symbol in ipairs(symbols) do
        local to_items = self:lr0_goto(items, symbol)
        if not empty(to_items) and added:insert(to_items) == nil then
          result:push(to_items)
          done = false
        end
      end
    end
  until done
  -- [TODO] GOTO関係の保持は？
  return result
end

function class:first_symbol(symbol)
  local result = linked_hash_table()
  if self:is_terminal_symbol(symbol) then
    result:insert(symbol, true)
  else
    for _, body in self:each_production(symbol) do
      if empty(body) then
        result:insert(epsilon)
      else
        set.union(result, self:first_symbols(body))
      end
    end
  end
  return result
end

function class:first_symbols(symbols)
  local result = linked_hash_table()
  for symbol in symbols:each() do
    local first = self:first_symbol(symbol)
    local have_epsilon = first[epsilon]
    first[epsilon] = nil
    set.union(result, first)
    if not have_epsilon then
      return result
    end
  end
  result[epsilon] = true
  return result
end

function class:lr1_closure(items)
  local productions = self.productions
  local added = hash_table()
  repeat
    local done = true
    for item in items:each() do
      local production = productions[item.id]
      local body = production.body
      local dot = item.dot
      local symbol = body[dot]
      if self:is_nonterminal_symbol(symbol) then
        local symbols = sequence():push(unpack(body, dot + 1)):push(item.la)
        for id in self:each_production(symbol) do
          local first = self:first_symbols(symbols)
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
  return items
end

function class:lr1_goto(I, to_symbol)
  local productions = self.productions
  local result = sequence()
  for item in I:each() do
    local id = item.id
    local production = productions[id]
    local dot = item.dot
    local symbol = production.body[dot]
    local a = item.la
    if symbol == to_symbol then
      result:push({ id = id, dot = dot + 1, la = a })
    end
  end
  return self:lr1_closure(result)
end

function class:lr1_items() -- [TODO] not used LALR(1)
  local symbols = self.symbols
  local result = sequence()
  for id in self:each_production(self.start_symbol) do
    result:push(self:lr1_closure(sequence():push({ id = id, dot = 1, la = eof })))
  end
  local added = hash_table()
  repeat
    local done = true
    for items in result:each() do
      -- [TODO] 全部のシンボルについて試す必要はない？
      for symbol in ipairs(symbols) do
        local to_items = self:lr1_goto(items, symbol)
        if not empty(to_items) and added:insert(to_items) == nil then
          result:push(to_items)
          done = false
        end
      end
    end
  until done
  return result
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
