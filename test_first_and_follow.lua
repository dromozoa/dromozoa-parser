-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-parser.
--
-- dromozoa-parser is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-parser is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-parser.  If not, see <http://www.gnu.org/licenses/>.

local equal = require "dromozoa.commons.equal"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence = require "dromozoa.commons.sequence"
local json = require "dromozoa.json"
local eliminate_left_recursion = require "dromozoa.parser.eliminate_left_recursion"
local first_symbols = require "dromozoa.parser.first_symbols"
local make_followset = require "dromozoa.parser.make_followset"
local test = require "test"

local prods = test.parse_grammar([[
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])
eliminate_left_recursion(prods)

assert(test.unparse_grammar(prods) == [[
E -> T E'
T -> F T'
F -> ( E ) | id
E' -> + T E' | ε
T' -> * F T' | ε
]])

assert(test.unparse_symbols(first_symbols(prods, sequence():push("F"))) == "( id")
assert(test.unparse_symbols(first_symbols(prods, sequence():push("T"))) == "( id")
assert(test.unparse_symbols(first_symbols(prods, sequence():push("E"))) == "( id")
assert(test.unparse_symbols(first_symbols(prods, sequence():push({ "E", "'" }))) == "+ ε")
assert(test.unparse_symbols(first_symbols(prods, sequence():push({ "T", "'" }))) == "* ε")

local followset = make_followset(prods, "E")
assert(test.unparse_symbols(followset["E"]) == "$ )")
assert(test.unparse_symbols(followset[{ "E", "'" }]) == "$ )")
assert(test.unparse_symbols(followset["T"]) == "+ $ )")
assert(test.unparse_symbols(followset[{ "T", "'" }]) == "+ $ )")
assert(test.unparse_symbols(followset["F"]) == "* + $ )")
