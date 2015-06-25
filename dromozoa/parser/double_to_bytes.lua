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

if string.pack then
  return function (v)
    return string.byte(string.pack("<d", v), 1, 8)
  end
else
  return function (v)
    local sign = 0
    local exponent = 0
    local fraction = 0

    if -math.huge < v and v < math.huge then
      if v == 0 then
        if string.format("%g", v) == "-0" then
          sign = 0x8000
        end
      else
        if v < 0 then
          sign = 0x8000
          v = -v
        end
        local m, e = math.frexp(v)
        if e < -1021 then
          fraction = math.ldexp(m, e + 1022)
        else
          exponent = e + 1022
          fraction = m * 2 - 1
        end
      end
    else
      exponent = 2047
      if v ~= math.huge then
        sign = 0x8000
        if v ~= -math.huge then
          fraction = 0.5
        end
      end
    end

    local u = fraction * 16
    local v = u % 1
    local b = u - v
    u = v * 256
    v = u % 1
    local c = u - v
    u = v * 256
    v = u % 1
    local d = u - v
    u = v * 256
    v = u % 1
    local e = u - v
    u = v * 256
    v = u % 1
    local f = u - v
    u = v * 256
    v = u % 1
    local g = u - v
    local h = v * 256

    local ab = sign + exponent * 16 + b
    b = ab % 256
    local a = (ab - b) / 256

    return h, g, f, e, d, c, b, a
  end
end
