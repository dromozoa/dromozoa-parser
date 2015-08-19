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

assert(test.unparse_grammar(prods) == [[
S -> A a | b
A -> A c | S d | ε
]])

eliminate_left_recursion(prods)

assert(test.unparse_grammar(prods) == [[
S -> A a | b
A -> b d A' | A'
A' -> c A' | a d A' | ε
]])
