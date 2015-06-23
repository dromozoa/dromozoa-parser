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

local type = type
local next = next
local getmetatable = getmetatable

local function equal(a, b)
  if a == b then
    return true
  else
    if type(a) == "table" and type(b) == "table" then
      for k, u in next, a do
        local v = b[k]
        if v == nil or not equal(u, v) then
          return false
        end
      end
      for k in next, b do
        if a[k] == nil then
          return false
        end
      end
      return getmetatable(a) == getmetatable(b)
    else
      return false
    end
  end
end

return equal
