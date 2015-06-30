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

return {
  insert = function (map, key, value)
    local v = map[key]
    if v then
      local n = #v + 1
      v[n] = value
      return n
    else
      map[key] = { value }
      return 1
    end
  end;

  each = function (map)
    return coroutine.wrap(function ()
      for k, v in pairs(map) do
        for i = 1, #v do
          coroutine.yield(k, v[i])
        end
      end
    end)
  end;
}
