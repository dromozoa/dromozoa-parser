local linked_list = require "dromozoa.parser.linked_list"

local list = linked_list()

print(list:push_back(4))
print(list:push_back(5))
print(list:push_back(6))
print(list:push_front(1))
print(list:push_front(2))
print(list:push_front(3))
print("--")
print(list:pop_front())
print(list:pop_back())
print("--")

for id, v in list:each() do
  print(id, v)
end

local id = list:push_back(42)
assert(list:get(id) == 42)
assert(list:set(id, 69) == 42)
assert(list:get(id) == 69)
assert(list:pop_back() == 69)
