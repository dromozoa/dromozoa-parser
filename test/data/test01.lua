local function f(a, b, c)
  print(a, b, c)
  return 42
end
f("foo", true, [[
abc
def
ghi
]])

data = { 1, 2, 3, 4 }
repeat
  local n = #data
  print(data[n])
  data[n] = nil
until n == 1

do
  local a, b = 1, 2
  local b = 3
  print(a, b)
end


