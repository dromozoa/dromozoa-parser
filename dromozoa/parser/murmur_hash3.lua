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

local uint32 = require "dromozoa.parser.uint32"

local add = uint32.add
local mul = uint32.mul
local bxor = uint32.bxor
local shl = uint32.shl
local shr = uint32.shr
local rotl = uint32.rotl
local decode_uint64 = uint32.decode_uint64
local decode_double = uint32.decode_double

local function update1(h1, k1)
  k1 = mul(k1, 0xCC9E2D51)
  k1 = rotl(k1, 15)
  k1 = mul(k1, 0x1B873593)
  h1 = bxor(h1, k1)
  return h1
end

local function update2(h1)
  h1 = rotl(h1, 13)
  h1 = mul(h1, 5)
  h1 = add(h1, 0xE6546B64)
  return h1
end

local function finalize(h1, n)
  h1 = bxor(h1, n)
  h1 = bxor(h1, shr(h1, 16))
  h1 = mul(h1, 0x85EBCA6B)
  h1 = bxor(h1, shr(h1, 13))
  h1 = mul(h1, 0xC2B2AE35)
  h1 = bxor(h1, shr(h1, 16))
  return h1
end

return {
  uint32 = function(key, seed)
    local h1 = seed
    h1 = update1(h1, key)
    h1 = update2(h1)
    return finalize(h1, 4)
  end;

  uint64 = function(key, seed)
    local h1 = seed
    local a, b = decode_uint64(key)
    h1 = update1(h1, a)
    h1 = update2(h1)
    h1 = update1(h1, b)
    h1 = update2(h1)
    return finalize(h1, 8)
  end;

  double = function(key, seed)
    local h1 = seed
    local a, b = decode_double(key)
    h1 = update1(h1, a)
    h1 = update2(h1)
    h1 = update1(h1, b)
    h1 = update2(h1)
    return finalize(h1, 8)
  end;

  string = function(key, seed)
    local h1 = seed
    local n = #key
    local m = n - n % 4
    for i = 4, m, 4 do
      local a, b, c, d = string.byte(key, i - 3, i)
      h1 = update1(h1, a + b * 0x100 + c * 0x10000 + d * 0x1000000)
      h1 = update2(h1)
    end
    if m < n then
      local a, b, c = string.byte(key, m + 1, n)
      if c then
        h1 = update1(h1, a + b * 0x100 + c * 0x10000)
      elseif b then
        h1 = update1(h1, a + b * 0x100)
      else
        h1 = update1(h1, a)
      end
    end
    return finalize(h1, n)
  end;
}
