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
local syntax_tree = require "dromozoa.parser.syntax_tree"

local ast = syntax_tree()

local B = ast:builder()
B.foo = B.a + B.b + B.c
B.foo = B.d * B.e + B.f
B.foo = B.g + B.h * B.i
B.bar = B.a + (B.b + B.c)
B.bar = B.d * (B.e + B.f)
B.baz = (B.a + B.b) * (B.c + B.d)
B.qux = (B.a + B.b + B.c) * (B.d + B.e + B.f)

ast:write_graphviz(assert(io.open("test1.dot", "w"))):close()
local grammar = ast:to_grammar()
ast:write_graphviz(assert(io.open("test2.dot", "w"))):close()

assert(equal(grammar.prods, {
  foo = {
    { "a" }; { "b" }; { "c" };
    { "d", "e" }; { "f" };
    { "g" }; { "h", "i" };
  };
  bar = {
    { "a" }; { "b" }; { "c" };
    { "d", "e" }; { "d", "f" };
  };
  baz = {
    { "a", "c" }; { "a", "d" };
    { "b", "c" }; { "b", "d" };
  };
  qux = {
    { "a", "d" }; { "a", "e" }; { "a", "f" };
    { "b", "d" }; { "b", "e" }; { "b", "f" };
    { "c", "d" }; { "c", "e" }; { "c", "f" };
  }
}))
