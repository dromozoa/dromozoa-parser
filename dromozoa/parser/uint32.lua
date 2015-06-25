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

local function pack_double(v)
  local a = 0
  local b = 0
  if -math.huge < v and v < math.huge then
    if v == 0 then
      if string.format("%g", v) == "-0" then
        a = 0x80000000
      end
    else
      if v < 0 then
        a = 0x80000000
        v = -v
      end
      local m, e = math.frexp(v)
      if e < -1021 then
        b = math.ldexp(m, e + 1022) * 0x100000
      else
        a = a + (e + 1022) * 0x100000
        b = (m * 2 - 1) * 0x100000
      end
    end
  else
    a = 0x7FF00000
    if v ~= math.huge then
      a = a + 0x80000000
      if v ~= -math.huge then
        b = 0x80000
      end
    end
  end
  local c = b % 1
  return c * 0x100000000, a + b - c
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
      pack_double = function (v)
        return string.unpack("<I4I4", string.pack("<d", v))
      end;
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
    pack_double = pack_double;
  }
elseif bit then
  local bxor = bit.bxor
  local shl = bit.lshift
  local shr = bit.rshift
  local rotl = bit.rol
  local rotr = bit.ror
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
    pack_double = pack_double;
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
    pack_double = pack_double;
  }
end
