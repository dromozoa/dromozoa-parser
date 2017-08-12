-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local builder = require "dromozoa.parser.builder"
local driver = require "dromozoa.parser.driver"

local RE = builder.regexp
local _ = builder()

_:lexer()
  :_ (RE[[//[^\n]*\n]]) :skip()
  :_ (RE[[\s+]]) :skip()
  :_ (RE[[0|[1-9]\d*]]) :as "integer"
  :_ "+"
  :_ "*"
  :_ "("
  :_ ")"

_ :left "+"
  :left "*"

_"expression"
  :_ "expression" "+" "expression"
  :_ "expression" "*" "expression"
  :_ "(" "expression" ")"
  :_ "integer"

local lexer, grammar = _:build()
local parser, conflicts = grammar:lr1_construct_table(grammar:lalr1_items())
grammar:write_conflicts(io.stderr, conflicts)
local driver = driver(lexer, parser)

local source = [[
(1 + 2 * 3)
 *
  foo
   (4 * 5 + 6)
]]

local root, message = driver(source, "test.txt")
assert(not root)
assert(message == "test.txt:3:3: lexer error")
-- parser:write_graphviz("test.dot", root)
