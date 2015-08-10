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

return function (text)
  local prods = linked_hash_table()
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*#") then
      local head
      local body = sequence()
      for sym in line:gmatch("%S+") do
        if sym == "->" then
          assert(head ~= nil)
          assert(#body == 0)
        else
          if head == nil then
            head = sym
          else
            body:push(sym)
          end
        end
      end
      local bodies = prods[head]
      if bodies == nil then
        prods[head] = sequence():push(body)
      else
        bodies:push(body)
      end
    end
  end
  return prods
end
