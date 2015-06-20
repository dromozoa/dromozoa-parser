
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








local function mul_ref(a, b)
  return (a * b) & 0xFFFFFFFF
end



-- io.write(mul(65535, 65535), "\n")
-- io.write(mul(0x12345678, 0x12345678), "\n")
-- 
-- io.write(mul_ref(65535, 65535), "\n")
-- io.write(mul_ref(0x12345678, 0x12345678), "\n")

for i = 0, 32 do
  io.write(rotl(0x12345678, i), "\n")
  -- print(string.format("0x%08x", rotl(0x12345678, i)))
end

