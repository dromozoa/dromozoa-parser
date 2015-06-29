local link_list = require "dromozoa.parser.link_list"

local list = link_list()

list:push_front(1)
list:push_front(2)
list:push_front(3)
print(list:pop_front())

for v in list:each() do
  print(v)
end
