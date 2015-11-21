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
local linked_hash_table = require "dromozoa.commons.linked_hash_table"

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

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, prods, start)
    return setmetatable(class.new(prods, start), metatable)
  end;
})
