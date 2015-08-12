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
test.unparse_grammar(io.stdout, prods)
