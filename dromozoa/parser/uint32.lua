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

local function add(a, b)
  local c = a + b
  return c % 0x100000000
end

local function mul(a, b)
  local a1 = a % 0x10000
  local a2 = (a - a1) / 0x10000
  local c1 = a1 * b
  local c2 = a2 * b % 0x10000
  local c = c1 + c2 * 0x10000
  return c % 0x100000000
end

local function swap(v)
  local a = v % 0x100
  v = (v - a) / 0x100
  local b = v % 0x100
  v = (v - b) / 0x100
  local c = v % 0x100
  v = (v - c) / 0x100
  return a * 0x1000000 + b * 0x10000 + c * 0x100 + v
end

if _VERSION >= "Lua 5.3" then
  return assert(load([[
    return {
      add = function (a, b)
        local c = a + b
        return c & 0xFFFFFFFF
      end;
      mul = function (a, b)
        local c = a * b
        return c & 0xFFFFFFFF
      end;
      bxor = function (a, b)
        local c = a ~ b
        return c
      end;
      shl = function (a, b)
        local c = a << b
        return c & 0xFFFFFFFF
      end;
      shr = function (a, b)
        local c = a >> b
        return c
      end;
      rotl = function (a, b)
        local c1 = a << b
        local c2 = a >> (32 - b)
        local c = c1 | c2
        return c & 0xFFFFFFFF
      end;
      rotr = function (a, b)
        local c1 = a >> b
        local c2 = a << (32 - b)
        local c = c1 | c2
        return c & 0xFFFFFFFF
      end;
      swap = function(v)
        local a = v & 0xFF
        v = v >> 8
        local b = v & 0xFF
        v = v >> 8
        local c = v & 0xFF
        v = v >> 8
        return a << 24 | b << 16 | c << 8 | v
      end
    }
  ]]))()
elseif bit32 then
  return {
    add = add;
    mul = mul;
    bxor = bit32.bxor;
    shl = bit32.lshift;
    shr = bit32.rshift;
    rotl = bit32.lrotate;
    rotr = bit32.rrotate;
    swap = swap;
  }
elseif bit then
  local bxor = bit.bxor
  local shl = bit.lshift
  local shr = bit.rshift
  local rotl = bit.rol
  local rotr = bit.ror
  local swap = bit.bswap
  return {
    add = add;
    mul = mul;
    bxor = function (a, b)
      return bxor(a, b) % 0x100000000
    end;
    shl = function (a, b)
      return shl(a, b) % 0x100000000
    end;
    shr = function (a, b)
      return shr(a, b) % 0x100000000
    end;
    rotl = function (a, b)
      return rotl(a, b) % 0x100000000
    end;
    rotr = function (a, b)
      return rotr(a, b) % 0x100000000
    end;
    swap = function (v)
      return swap(v) % 0x100000000
    end;
  }
else
  local function bxor(a, b)
    local c = 0
    local d = 1
    for i = 1, 31 do
      local a1 = a % 2
      local b1 = b % 2
      if a1 ~= b1 then
        c = c + d
      end
      a = (a - a1) / 2
      b = (b - b1) / 2
      d = d * 2
    end
    local a2 = a % 2
    local b2 = b % 2
    if a2 ~= b2 then
      c = c + d
    end
    return c
  end

  local function shl(a, b)
    local b1 = 2 ^ b
    local b2 = 0x100000000 / b1
    local c = a % b2 * b1
    return c
  end

  local function shr(a, b)
    local b1 = 2 ^ b
    local c = a / b1
    return c - c % 1
  end

  local function rotl(a, b)
    local b1 = 2 ^ b
    local b2 = 0x100000000 / b1
    local a1 = a % b2
    local a2 = (a - a1) / b2
    local c = a1 * b1 + a2
    return c
  end

  local function rotr(a, b)
    local b1 = 2 ^ b
    local b2 = 0x100000000 / b1
    local a1 = a % b1
    local a2 = (a - a1) / b1
    local c = a1 * b2 + a2
    return c
  end

  return {
    add = add;
    mul = mul;
    bxor = bxor;
    shl = shl;
    shr = shr;
    rotl = rotl;
    rotr = rotr;
    swap = swap;
  }
end
