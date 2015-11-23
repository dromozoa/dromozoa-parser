-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local apply = require "dromozoa.commons.apply"
local equal = require "dromozoa.commons.equal"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local keys = require "dromozoa.commons.keys"
local sequence = require "dromozoa.commons.sequence"
local set = require "dromozoa.commons.set"
local dump = require "dromozoa.parser.grammar.dump"

local epsilon = {}

local class = {}

function class.new(prods, start)
  if start == nil then
    start = apply(prods:each())
  end
  return {
    prods = prods;
    start = start;
  }
end

function class:each_symbol()
  local prods = self.prods
  return coroutine.wrap(function ()
    local map = linked_hash_table()
    for head in prods:each() do
      map:insert(head)
      coroutine.yield(head, false)
    end
    for head, bodies in prods:each() do
      for body in bodies:each() do
        for symbol in body:each() do
          if map:insert(symbol) == nil then
            coroutine.yield(symbol, true)
          end
        end
      end
    end
  end)
end

function class:dump(out)
  return dump(out, self)
end

function class:eliminate_immediate_left_recursion(head1, bodies)
  local prods = self.prods
  local head2 = { head1, "'" }
  local bodies1 = sequence()
  local bodies2 = sequence()
  for body in bodies:each() do
    if equal(body[1], head1) then
      bodies2:push(sequence():copy(body, 2):push(head2))
    else
      bodies1:push(sequence():copy(body):push(head2))
    end
  end
  if #bodies2 > 0 then
    bodies2:push(sequence())
    prods[head1] = bodies1
    prods[head2] = bodies2
  end
end

function class:eliminate_left_recursion()
  local prods = self.prods
  local heads = keys(prods)
  for i = 1, #heads do
    local head1 = heads[i]
    local bodies1 = prods[head1]
    for j = 1, i - 1 do
      local head2 = heads[j]
      local bodies2 = prods[head2]
      local bodies = sequence()
      for body1 in bodies1:each() do
        if equal(body1[1], head2) then
          for body2 in bodies2:each() do
            bodies:push(sequence():copy(body2):copy(body1, 2))
          end
        else
          bodies:push(body1)
        end
      end
      bodies1 = bodies
    end
    self:eliminate_immediate_left_recursion(head1, bodies1)
  end
  return prods
end

function class:first_symbol(symbol)
  local prods = self.prods
  local first = linked_hash_table()
  local bodies = prods[symbol]
  if bodies == nil then
    first:insert(symbol)
  else
    for body in bodies:each() do
      if #body == 0 then
        first:insert(epsilon)
      else
        set.union(first, self:first_symbols(body))
      end
    end
  end
  return first
end

function class:first_symbols(symbols)
  local prods = self.prods
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

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, prods, start)
    return setmetatable(class.new(prods, start), metatable)
  end;
})
