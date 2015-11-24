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

local dumper = require "dromozoa.commons.dumper"
local equal = require "dromozoa.commons.equal"
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local sequence_writer = require "dromozoa.commons.sequence_writer"
local parser = require "dromozoa.parser"

local t = parser.syntax_tree()
local b = t:builder()
local A_prime = {"A"}
local epsilon = {}
b.S = b.A * b.a + b.b
b.A = b.b * b.d * b[A_prime] + b[A_prime]
b[A_prime] = b.c * b[A_prime] + b.a * b.d * b[A_prime] + b[epsilon]

t:write_graphviz(assert(io.open("test1.dot", "w"))):close()
local grammar = t:to_grammar()
t:write_graphviz(assert(io.open("test2.dot", "w"))):close()

assert(grammar.start == "S")
local code = grammar:encode()
-- io.write(code)
assert(equal(grammar, parser.grammar.decode(code)))

local t = parser.syntax_tree()
local b = t:builder()
b.E = b.E * b["+"] * b.T
    + b.T
b.T = b.T * b["*"] * b.F
    + b.F
b.F = b["("] * b.E * b[")"]
    + b.id

t:write_graphviz(assert(io.open("test1.dot", "w"))):close()
local grammar = t:to_grammar()
t:write_graphviz(assert(io.open("test2.dot", "w"))):close()

assert(grammar.start == "E")
local code = grammar:encode()
-- io.write(code)
assert(equal(grammar, parser.grammar.decode(code)))

local symbols = linked_hash_table()
for symbol, is_terminal_symbol in grammar:each_symbol() do
  assert(symbols:insert(symbol, is_terminal_symbol) == nil)
end
assert(equal(symbols, {
  E = false;
  T = false;
  F = false;
  ["+"] = true;
  ["*"] = true;
  ["("] = true;
  [")"] = true;
  id = true;
}))


