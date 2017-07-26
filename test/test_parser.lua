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

local dumper = require "dromozoa.commons.dumper"
local builder = require "dromozoa.parser.builder"
local parser = require "dromozoa.parser.parser"

local _ = builder()
local P = builder.pattern
local R = builder.range
local S = builder.set

_:lexer()
  :_(S" \t\n\v\f\r"^"+") :skip()
  :_(R"09"^"+") :as "id"
  :_ "+"
  :_ "*"
  :_ "("
  :_ ")"

_ :left "+"
  :left "*"

_"E"
  :_ "E" "+" "E"
  :_ "E" "*" "E"
  :_ "(" "E" ")"
  :_ "id"

local scanner, grammar = _:build()
print(dumper.encode(grammar, { pretty = true, stable = true }))

local parser = grammar:lr1_construct_table(grammar:lalr1_items())
print(dumper.encode(parser, { stable = true }))

local _ = _.symbol_table

assert(parser(_["id"], { value = "17" }))
assert(parser(_["+"],  { value = "+" }))
assert(parser(_["id"], { value = "23" }))
assert(parser(_["*"],  { value = "*" }))
assert(parser(_["id"], { value = "37" }))
local tree = assert(parser(1))

parser:write_graphviz("test.dot", tree)
