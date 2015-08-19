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
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local each_symbol = require "dromozoa.parser.each_symbol"

return function (closure)
  local class = {
    closure = closure;
  }

  function class.goto_(prods, items, symbol)
    local goto_items = sequence()
    for item in items:each() do
      local head, body, dot = item[1], item[2], item[3]
      if equal(body[dot], symbol) then
        goto_items:push(sequence():push(head, body, dot + 1, item[4]))
      end
    end
    return class.closure(prods, goto_items)
  end

  function class.items(prods, start)
    local set_of_items = linked_hash_table()
    set_of_items:insert(class.closure(prods, sequence():push(start)))
    local done
    repeat
      done = true
      for items in set_of_items:each() do
        for symbol in each_symbol(prods) do
          local goto_items = class.goto_(prods, items, symbol)
          if #goto_items > 0 then
            if set_of_items:insert(goto_items) == nil then
              done = false
            end
          end
        end
      end
    until done
    return set_of_items
  end

  return class
end
