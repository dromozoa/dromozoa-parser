-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local function encode(value)
  local t = type(value)
  if t == "number" then
    return ("%.17g"):format(value)
  elseif t == "string" then
    return ("%q"):format(value)
  elseif t == "table" then
    local min
    local max
    local n = 0
    for k in pairs(value) do
      assert(type(k) == "number" and k % 1 == 0)
      if not min or min > k then
        min = k
      end
      if not max or max < k then
        max = k
      end
      n = n + 1
    end
    if not min then
      return "{}"
    end
    local data = {}
    if min < 1 or n * 1.8 < max then
      for i = min, max do
        local v = value[i]
        if v then
          data[#data + 1] = "[" .. i .. "]=" .. encode(v)
        end
      end
    else
      for i = 1, max do
        local v = value[i]
        if v then
          data[#data + 1] = encode(v)
        else
          data[#data + 1] = "nil"
        end
      end
    end
    return "{" .. table.concat(data, ",") .. "}"
  end
end

return encode
