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

if _VERSION >= "Lua 5.3" then
  return load([[
    return {
      add = function (x, y)
        return (x + y) & 0xFFFFFFFF
      end;
      mul = function (x, y)
        return (x * y) & 0xFFFFFFFF
      end;
      rotl = function (x, y)
        return (x << y | x >> (32 - y)) & 0xFFFFFFFF
      end;
      bxor = function (x, y)
        return x ~ y
      end;
      shr = function (x, y)
        return x >> y
      end
    }
  ]])()
elseif bit32 then
  local band = bit32.band
  local shl = bit32.lshift
  local shr = bit32.rshift
  return {
    add = function (x, y)
      return band(x + y, 0xFFFFFFFF)
    end;
    mul = function (x, y)
      local a = shr(x, 16)
      local b = band(x, 0xFFFF)
      a = shl(band(a * y, 0xFFFF), 16)
      b = b * y
      return band(a + b, 0xFFFFFFFF)
    end;
    rotl = bit32.lrotate;
    bxor = bit32.bxor;
    shr = shr;
  }
elseif bit then
  local band = bit.band
  local shl = bit.lshift
  local shr = bit.rshift
  local rotl = bit.rol
  local bxor = bit.bxor
  return {
    add = function (x, y)
      return (x + y) % 0x100000000
    end;
    mul = function (x, y)
      local a = shr(x, 16)
      local b = band(x, 0xFFFF)
      a = shl(band(a * y, 0xFFFF), 16)
      b = b * y
      return (a + b) % 0x100000000
    end;
    rotl = function (x, y)
      return rotl(x, y) % 0x100000000
    end;
    bxor = function (x, y)
      return bxor(x, y) % 0x100000000
    end;
    shr = shr;
  }
else
  local function add(x, y)
    local z = x + y
    return z % 0x100000000
  end

  local function mul(a, b)
    local a1 = a % 0x10000
    local a2 = (a - a1) / 0x10000
    local b1 = b % 0x10000
    local c = a1 * b + a2 * b1 * 0x10000
    return c % 0x100000000
  end

  local function rotl(a, b)
    local c = 2 ^ (32 - b)
    local a1 = a % c
    local a2 = (a - a1) / c
    return a1 * (2 ^ b) + a2
  end

  local function bxor(a, b)
    local c = 0
    local d = 1
    for i = 1, 32 do
      local a1 = a % 2
      local b1 = b % 2

      if a1 ~= b1 then
        c = c + d
      end
      d = d * 2

      a = (a - a1) / 2
      b = (b - b1) / 2
    end
    return c
  end

  local function shr(a, b)
    local c = a / (2 ^ b)
    return c - c % 1
  end

  return {
    add = add;
    mul = mul;
    rotl = rotl;
    bxor = bxor;
    shr = shr;
  }
end
