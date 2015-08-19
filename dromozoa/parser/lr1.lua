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

local clone = require "dromozoa.commons.clone"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local first_symbols = require "dromozoa.parser.first_symbols"
local lr_impl = require "dromozoa.parser.lr_impl"

return lr_impl(function (prods, items)
  local items = clone(items)
  local added = linked_hash_table()
  local done
  repeat
    done = true
    for item in items:each() do
      local head, body, dot, term = item[1], item[2], item[3], item[4]
      local symbol = body[dot]
      if symbol ~= nil then
        local bodies = prods[symbol]
        if bodies ~= nil then
          local first = first_symbols(prods, sequence():copy(body, dot + 1):push(term))
          for body in bodies:each() do
            for term in first:each() do
              local item = sequence():push(symbol, body, 1, term)
              if added:insert(item) == nil then
                items:push(item)
                done = false
              end
            end
          end
        end
      end
    end
  until done
  return items
end)
