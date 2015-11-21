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

local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local lr0_kernel_items = require "dromozoa.parser.lr0_kernel_items"
local determine_lookaheads = require "dromozoa.parser.determine_lookaheads"
local set_union = require "dromozoa.parser.set_union"

return function (prods, start, set_of_kernel_items)
  local generate, propagate = determine_lookaheads(prods, start, set_of_kernel_items)
  local done
  repeat
    done = true
    for item, from_items in propagate:each() do
      local symbols = generate[item]
      if symbols == nil then
        symbols = linked_hash_table()
        generate[item] = symbols
      end
      for from_item in from_items:each() do
        local from_symbols = generate[from_item]
        if from_symbols ~= nil then
          if set_union(symbols, from_symbols) > 0 then
            done = false
          end
        end
      end
    end
  until done

  local lalr_set_of_kernel_items = linked_hash_table()
  for kernel_items in set_of_kernel_items:each() do
    local lalr_kernel_items = sequence()
    for kernel_item in kernel_items:each() do
      local head, body, dot = kernel_item[1], kernel_item[2], kernel_item[3]
      local symbols = generate[kernel_item]
      for symbol in symbols:each() do
        lalr_kernel_items:push({ head, body, dot, symbol })
      end
    end
    lalr_set_of_kernel_items:insert(lalr_kernel_items)
  end

  return lalr_set_of_kernel_items
end
