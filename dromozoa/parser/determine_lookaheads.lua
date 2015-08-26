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
local lr0_kernel_items = require "dromozoa.parser.lr0_kernel_items"
local lr1 = require "dromozoa.parser.lr1"
local set_union = require "dromozoa.parser.set_union"

return function (prods, start)
  local set_of_kernel_items = lr0_kernel_items(prods, start)
  local lookaheads = linked_hash_table()
  local generate = linked_hash_table()
  local propagate = linked_hash_table()
  for kernel_items in set_of_kernel_items:each() do
    for kernel_item in kernel_items:each() do
      local kernel_head, kernel_body, kernel_dot = kernel_item[1], kernel_item[2], kernel_item[3]
      local items = lr1.closure(
          prods,
          sequence()
              :push({ kernel_head, kernel_body, kernel_dot, { "#" } }))
      for item in items:each() do
        local head, body, dot, term = item[1], item[2], item[3], item[4]
        local symbol = body[dot]
        if symbol ~= nil then
          local to_item = { head, body, dot + 1 }
          if equal(term, { "#" }) then
            lookaheads:insert({ { head, body, dot + 1, { "#" } }, kernel_item, symbol })
            local from_items = propagate[to_item]
            if from_items == nil then
              from_items = linked_hash_table()
              propagate[to_item] = from_items
            end
            from_items:insert(kernel_item)
          else
            lookaheads:insert({ { head, body, dot + 1, term }, nil, symbol })
            generate:insert(to_item, term)
          end
        end
      end
    end
  end
  return generate, propagate
end
