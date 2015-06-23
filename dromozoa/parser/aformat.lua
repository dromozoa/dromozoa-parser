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

if pcall(string.format, "%a", 0) then
  return function (value)
    return string.format("%.13a", value)
  end
else
  return function (value)
    if -math.huge < value and value < math.huge then
      if value == 0 then
        return string.format("%gx0.0000000000000p+0", value)
      else
        local format
        if value > 0 then
          format = "0x1.%08x%05xp%+d"
        else
          format = "-0x1.%08x%05xp%+d"
          value = -value
        end
        local m, e = math.frexp(value)
        m = m * 2 - 1
        e = e - 1
        local a = m * 0x100000000
        local b = a % 1
        a = a - b
        b = b * 0x100000
        return string.format(format, a, b, e)
      end
    else
      return string.format("%f", value)
    end
  end
end
