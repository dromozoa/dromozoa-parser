local parse = require "dromozoa.parser.parse"
local json = require "dromozoa.json"

local names, productions = parse([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])

for rule in productions:each() do
  local head, body = rule[1], rule[2]
  io.write(names:find(head), " ->")
  for symbol in body:each() do
    io.write(" ", (names:find(symbol)))
  end
  io.write("\n")
end
