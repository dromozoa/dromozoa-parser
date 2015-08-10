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

for rule in prods:each() do
  local head, body = rule[1], rule[2]
  io.write(head, " ->")
  for sym in body:each() do
    io.write(" ", sym)
  end
  io.write("\n")
end
