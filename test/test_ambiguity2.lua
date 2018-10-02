-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local _ = builder()

_:lexer()
  :_ "=="
  :_ "!="
  :_ "<"
  :_ "<="
  :_ ">"
  :_ ">="
  :_ "id"

_ :nonassoc "==" "!="
  :nonassoc "<" "<=" ">" ">="

_ "E"
  :_ "E" "==" "E"
  :_ "E" "!=" "E"
  :_ "E" "<" "E"
  :_ "E" "<=" "E"
  :_ "E" ">" "E"
  :_ "E" ">=" "E"
  :_ "id"

local lexer, grammar = _:build()
local set_of_items, transitions = grammar:lalr1_items()
local parser, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
grammar:write_conflicts(io.stderr, conflicts)

local source = [[id<id<id<id<id<id<]]
local terminal_nodes = assert(lexer(source, "test.txt"))
local accepted_node, message = parser(terminal_nodes, source, "test.txt")
assert(not accepted_node)
assert(message == "test.txt:1:6: parser error")
