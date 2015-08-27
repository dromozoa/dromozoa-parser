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
local lr0 = require "dromozoa.parser.lr0"

return function (prods, start)
  local set_of_items = lr0.items(prods, start)
  local set_of_kernel_items = linked_hash_table()
  for items in set_of_items:each() do
    local kernel_items = sequence()
    for item in items:each() do
      local dot = item[3]
      if equal(item, start) or dot > 1 then
        kernel_items:push(item)
      end
    end
    if #kernel_items > 0 then
      set_of_kernel_items:insert(kernel_items)
    end
  end
  return set_of_kernel_items
end
