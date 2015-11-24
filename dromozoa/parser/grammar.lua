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
local dumper = require "dromozoa.commons.dumper"
local empty = require "dromozoa.commons.empty"
local equal = require "dromozoa.commons.equal"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local keys = require "dromozoa.commons.keys"
local sequence = require "dromozoa.commons.sequence"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local set = require "dromozoa.commons.set"
local dump = require "dromozoa.parser.grammar.dump"
local eliminate_left_recursion = require "dromozoa.parser.grammar.eliminate_left_recursion"

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

function class:dump(out)
  return dump(out, self)
end

function class:encode()
  return self:dump(sequence_writer()):concat()
end

function class.decode(code)
  return dumper.decode(code)
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

function class:eliminate_left_recursion()
  eliminate_left_recursion(self.prods)
  return self
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
