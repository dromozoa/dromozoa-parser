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

local function fmix32(h)
  io.write(string.format("fmix32(1): 0x%08X\n", h))
  local a = h / 0x10000 -- >>16
  a = a - a % 1
  h = bxor(h, a)
  io.write(string.format("fmix32(2): 0x%08X\n", h))
  h = mul(h, 0x85EBCA6B) -- >>13
  io.write(string.format("fmix32(3): 0x%08X\n", h))
  local b = h / 0x2000
  b = b - b % 1
  h = bxor(h, b)
  io.write(string.format("fmix32(4): 0x%08X\n", h))
  h = mul(h, 0xC2B2AE35)
  io.write(string.format("fmix32(5): 0x%08X\n", h))
  local c = h / 0x10000 -- >>16
  c = c - c % 1
  h = bxor(h, c)
  io.write(string.format("fmix32(6): 0x%08X\n", h))
  return h
end

local function murmur_hash3(s, seed)
  local h1 = seed

  local c1 = 0xCC9E2D51
  local c2 = 0x1B873593

  local n = #s
  local x = n % 4
  local m = n - x

  -- 3 -> 0
  -- 4 -> 4
  -- 5 -> 4
  -- 6 -> 4
  -- 7 -> 4
  -- 8 -> 8

  for i = 4, m, 4 do
    local a, b, c, d = string.byte(s, i - 3, i)
    local k1 = a + b * 0x100 + c * 0x10000 + d * 0x1000000
    io.write(string.format("%d\t0x%08X\n", i, k1))
    k1 = mul(k1, c1)
    k1 = rotl(k1, 15)
    k1 = mul(k1, c2)
    h1 = bxor(h1, k1)
    h1 = rotl(h1, 13)
    h1 = mul(h1, 5)
    h1 = add(h1, 0xe6546b64)
  end
  if x > 0 then
    local a, b, c = string.byte(s, m + 1, n)
    print(m, n, a, b, c)
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
    io.write(string.format("%d\t0x%08X\n", n, k1))
    k1 = mul(k1, c1)
    k1 = rotl(k1, 15)
    k1 = mul(k1, c2)
    h1 = bxor(h1, k1)
  end

  io.write(string.format("h1: 0x%08X\n", h1))

  h1 = bxor(h1, n)
  h1 = fmix32(h1)

  return h1
end

local h = murmur_hash3(arg[1], 0)
io.write(string.format("0x%08X\t%d\n", h, h))


