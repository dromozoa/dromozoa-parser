local link_list = require "dromozoa.parser.link_list"

local list = link_list()

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

for v in list:each() do
  print(v)
end

