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
local parser = require "dromozoa.parser"

local ast = parser.syntax_tree()
local B = ast:builder()
B.E = B.E * B["+"] * B.T
    + B.T
B.T = B.T * B["*"] * B.F
    + B.F
B.F = B["("] * B.E * B[")"]
    + B.id
ast:write_graphviz(assert(io.open("test1.dot", "w"))):close()
local grammar = ast:to_grammar()
ast:write_graphviz(assert(io.open("test2.dot", "w"))):close()

assert(grammar.start == "E")
grammar.start = "T"
assert(grammar.start == "T")

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

grammar:eliminate_left_recursion()


