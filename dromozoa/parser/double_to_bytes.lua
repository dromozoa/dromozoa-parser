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
    return string.unpack("<I4I4", string.pack("<d", v))
  end
else
  return function (v)
    local sign = 0
    local exponent = 0
    local fraction = 0

    if -math.huge < v and v < math.huge then
      if v == 0 then
        if string.format("%g", v) == "-0" then
          sign = 0x80000000
        end
      else
        if v < 0 then
          sign = 0x80000000
          v = -v
        end
        local m, e = math.frexp(v)
        if e < -1021 then
          fraction = math.ldexp(m, e + 1022) * 0x100000
        else
          exponent = (e + 1022) * 0x100000
          fraction = (m * 2 - 1) * 0x100000
        end
      end
    else
      exponent = 0x7FF00000
      if v ~= math.huge then
        sign = 0x80000000
        if v ~= -math.huge then
          fraction = 0x80000
        end
      end
    end

    local b = fraction
    local a = b % 1
    b = b - a
    b = sign + exponent + b
    a = a * 0x100000000
    return a, b
  end
end
