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
local set_union = require "dromozoa.parser.set_union"

local EPSILON = {}
local first_symbols

local function first_symbol(prods, symbol)
  local first = linked_hash_table()
  local bodies = prods[symbol]
  if bodies == nil then
    first:insert(symbol)
  else
    for body in bodies:each() do
      if #body == 0 then
        first:insert(EPSILON)
      else
        set_union(first, first_symbols(prods, body))
      end
    end
  end
  return first
end

first_symbols = function (prods, symbols)
  local first = linked_hash_table()
  for symbol in symbols:each() do
    set_union(first, first_symbol(prods, symbol))
    if first:remove(EPSILON) == nil then
      return first
    end
  end
  first:insert(EPSILON)
  return first
end

return first_symbols
