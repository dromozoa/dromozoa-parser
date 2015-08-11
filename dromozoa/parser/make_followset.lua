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
local first_symbols = require "dromozoa.parser.first_symbols"
local set_union = require "dromozoa.parser.set_union"

return function (prods, start)
  local followset = linked_hash_table()
  for head in prods:each() do
    followset[head] = linked_hash_table()
  end
  followset[start]:insert({ "$" })
  local done
  repeat
    done = true
    for head, bodies in prods:each() do
      for body in bodies:each() do
        for i = 1, #body do
          local symbol = body[i]
          if prods[symbol] ~= nil then
            local first = first_symbols(prods, sequence(body, i + 1))
            local removed = first:remove({}) ~= nil
            if set_union(followset[symbol], first) > 0 then
              done = false
            end
            if removed then
              if set_union(followset[symbol], followset[head]) > 0 then
                done = false
              end
            end
          end
        end
      end
    end
  until done
  return followset
end
