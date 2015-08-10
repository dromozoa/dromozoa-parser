local clone = require "dromozoa.commons.clone"
local parse_grammar = require "dromozoa.parser.parse_grammar"
local eliminate_left_recursion = require "dromozoa.parser.eliminate_left_recursion"

local prods = parse_grammar([[
S -> A a
S -> b
A -> A c
A -> S d
A ->
]])

local prods2 = clone(prods)
eliminate_left_recursion(prods2)

local function write_symbol(sym)
  if type(sym) == "table" then
    for i = 1, #sym do
      write_symbol(sym[i])
    end
  else
    io.write(sym)
  end
end

for head, bodies in prods2:each() do
  for body in bodies:each() do
    write_symbol(head)
    io.write(" ->")
    for sym in body:each() do
      io.write(" ")
      write_symbol(sym)
    end
    io.write("\n")
  end
end
