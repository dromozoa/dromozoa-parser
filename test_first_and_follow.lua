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
local parse_grammar = require "dromozoa.parser.parse_grammar"
local eliminate_left_recursion = require "dromozoa.parser.eliminate_left_recursion"
local first_symbols = require "dromozoa.parser.first_symbols"
local make_followset = require "dromozoa.parser.make_followset"

local prods = parse_grammar([[
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])

eliminate_left_recursion(prods)

local expected = linked_hash_table()
expected["E"] = {
  { "T", { "E", "'" } };
}
expected[{ "E", "'" }] = {
  { "+", "T", { "E", "'" } };
  {};
}
expected["T"] = {
  { "F", { "T", "'" } };
}
expected[{ "T", "'" }] = {
  { "*", "F", { "T", "'" } };
  {};
}
expected["F"] = {
  { "(", "E", ")" };
  { "id" };
}
assert(equal(prods, expected))

local expected = linked_hash_table()
expected:insert("(")
expected:insert("id")
assert(equal(first_symbols(prods, sequence({ "F" })), expected))
assert(equal(first_symbols(prods, sequence({ "T" })), expected))
assert(equal(first_symbols(prods, sequence({ "E" })), expected))

local expected = linked_hash_table()
expected:insert("+")
expected:insert({})
assert(equal(first_symbols(prods, sequence({ { "E", "'" } })), expected))

local expected = linked_hash_table()
expected:insert("*")
expected:insert({})
assert(equal(first_symbols(prods, sequence({ { "T", "'" } })), expected))

local followset = make_followset(prods, "E")

local expected = linked_hash_table()
expected:insert(")")
expected:insert({ "$" })
assert(equal(followset["E"], expected))
assert(equal(followset[{ "E", "'" }], expected))

local expected = linked_hash_table()
expected:insert("+")
expected:insert(")")
expected:insert({ "$" })
assert(equal(followset["T"], expected))
assert(equal(followset[{ "T", "'" }], expected))

local expected = linked_hash_table()
expected:insert("+")
expected:insert("*")
expected:insert(")")
expected:insert({ "$" })
assert(equal(followset["F"], expected))
