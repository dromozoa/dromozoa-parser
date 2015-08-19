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

local equal = require "dromozoa.commons.equal"
local sequence = require "dromozoa.commons.sequence"
local items = require "dromozoa.parser.items"
local lr1_closure = require "dromozoa.parser.lr1_closure"

local class = {
  closure = lr1_closure;
}

function class.goto_(prods, items, symbol)
  local goto_items = sequence()
  for item in items:each() do
    local head, body, dot, term = item[1], item[2], item[3], item[4]
    if equal(body[dot], symbol) then
      goto_items:push(sequence():push(head, body, dot + 1, term))
    end
  end
  return class.closure(prods, goto_items)
end

function class.items(prods, start)
  return items(class, prods, start)
end

return class
