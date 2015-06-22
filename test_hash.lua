local uint32 = require "dromozoa.parser.uint32"

local add = uint32.add
local mul = uint32.mul
local rotl = uint32.rotl
local bxor = uint32.bxor
local shr = uint32.shr

local function make_k1(a, b, c, d)
  if d then
    return a + b * 0x100 + c * 0x10000 + d * 0x1000000
  else
    assert(a)
    local k1 = 0
    if c then
      k1 = bxor(k1, c * 0x10000)
    end
    if b then
      k1 = bxor(k1, b * 0x100)
    end
    if a then
      k1 = bxor(k1, a)
    end
    return k1
  end
end

local function update(h1, k1)
  k1 = mul(k1, 0xCC9E2D51)
  k1 = rotl(k1, 15)
  k1 = mul(k1, 0x1B873593)
  h1 = bxor(h1, k1)
  return h1
end

local function update_each(h1, k1)
  h1 = update(h1, k1)
  h1 = rotl(h1, 13)
  h1 = mul(h1, 5)
  h1 = add(h1, 0xe6546b64)
  return h1
end

local function fmix32(h)
  h = bxor(h, shr(h, 16))
  h = mul(h, 0x85EBCA6B)
  h = bxor(h, shr(h, 13))
  h = mul(h, 0xC2B2AE35)
  h = bxor(h, shr(h, 16))
  return h
end

local function finalize(h1, n)
  h1 = bxor(h1, n)
  h1 = fmix32(h1)
  return h1
end

local function murmur_hash3(s, seed)
  local h1 = seed

  local n = #s
  local x = n % 4
  local m = n - x

  for i = 4, m, 4 do
    local k1 = make_k1(string.byte(s, i - 3, i))
    h1 = update_each(h1, k1)
  end
  if x > 0 then
    local k1 = make_k1(string.byte(s, m + 1, n))
    h1 = update(h1, k1)
  end

  h1 = finalize(h1, n)
  return h1
end

local h = murmur_hash3(arg[1], 0)
io.write(string.format("0x%08X\t%d\n", h, h))


