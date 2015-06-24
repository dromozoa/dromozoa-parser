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

return function (key, seed)
  local h1 = seed
  local n

  local t = type(key)
  if t == "number" then
    n = 4
    local k1 = key
    h1 = update1(h1, k1)
    h1 = update2(h1)
  else
    n = #key
    local m = n - n % 4

    for i = 4, m, 4 do
      local a, b, c, d = string.byte(key, i - 3, i)
      local k1 = a + shl(b, 8) + shl(c, 16) + shl(d, 24)
      h1 = update1(h1, k1)
      h1 = update2(h1)
    end

    if m < n then
      local a, b, c = string.byte(key, m + 1, n)
      local k1 = a + shl(b or 0, 8) + shl(c or 0, 16)
      h1 = update1(h1, k1)
    end
  end

  h1 = finalize(h1, n)
  return h1
end
