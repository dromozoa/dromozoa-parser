local parse = require "dromozoa.parser.parse"
local json = require "dromozoa.json"

local prods = parse([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])

for head, bodies in prods:each() do
  for body in bodies:each() do
    io.write(head, " ->")
    for sym in body:each() do
      io.write(" ", sym)
    end
    io.write("\n")
  end
end
