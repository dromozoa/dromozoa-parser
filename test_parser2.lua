local clone = require "dromozoa.commons.clone"
local eliminate_left_recursion = require "dromozoa.parser.eliminate_left_recursion"
local test = require "test"

local prods = test.parse_grammar([[
S -> A a
S -> b
A -> A c
A -> S d
A ->
]])

local prods2 = clone(prods)
eliminate_left_recursion(prods2)

local function write_symbol(symbol)
  if type(symbol) == "table" then
    for i = 1, #symbol do
      write_symbol(symbol[i])
    end
  else
    io.write(symbol)
  end
end

for head, bodies in prods2:each() do
  for body in bodies:each() do
    write_symbol(head)
    io.write(" ->")
    for symbol in body:each() do
      io.write(" ")
      write_symbol(symbol)
    end
    io.write("\n")
  end
end
