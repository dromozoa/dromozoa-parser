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
local lr1 = require "dromozoa.parser.lr1"

local function insert_action(actions, k, v)
  local u = actions:insert(k, v)
  assert(u == nil or equal(u, v))
end

return function (prods, start)
  local set_of_items = lr1.items(prods, start)
  local map_of_items = linked_hash_table()

  local n = 0
  for items in set_of_items:each() do
    set_of_items[items] = n
    map_of_items[n] = items
    n = n + 1
  end

  local start_head = start[1]

  local actions = linked_hash_table()
  for items, i in set_of_items:each() do
    for item in items:each() do
      local head, body, dot, term = item[1], item[2], item[3], item[4]
      local symbol = body[dot]
      if symbol == nil then
        if equal(head, start_head) then
          insert_action(actions, { i, { "$" } }, { "accept" })
        else
          insert_action(actions, { i, term }, { "reduce", { head, body } })
        end
      elseif prods[symbol] == nil then
        local goto_items = lr1.goto_(prods, items, symbol)
        local j = set_of_items[goto_items]
        assert(j ~= nil)
        insert_action(actions, { i, symbol }, { "shift", j })
      end
    end
  end

  local gotos = linked_hash_table()
  for items, i in set_of_items:each() do
    for head in prods:each() do
      local goto_items = lr1.goto_(prods, items, head)
      local j = set_of_items[goto_items]
      if j ~= nil then
        if gotos:insert({ i, head }, j) ~= nil then
          error("???")
        end
      end
    end
  end

  return actions, gotos
end
