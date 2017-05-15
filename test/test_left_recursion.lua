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

local clone = require "dromozoa.commons.clone"
local dumper = require "dromozoa.commons.dumper"
local builder = require "dromozoa.parser.builder"

local _ = builder()

_ :lit "a"
  :lit "b"
  :lit "c"
  :lit "d"

_ "S"
  :_ "A" "a"
  :_ "b"

_ "A"
  :_ "A" "c"
  :_ "S" "d"
  :_ ()

local scanner, grammar, writer = _:build()

-- writer:write_first(io.stdout, grammar:first_symbol(_.symbol_table["A"])):write("\n")

local elr_grammar, elr_writer = grammar:eliminate_left_recursion(_.symbol_names)
local elr_productions = elr_grammar.productions

for i, production in ipairs(elr_productions) do
  io.write(i, ": ")
  elr_writer:write_production(io.stdout, production)
  io.write("\n")
end

io.write("--\n")
elr_writer:write_first(io.stdout, elr_grammar:first_symbol(_.symbol_table["S"])):write("\n")
elr_writer:write_first(io.stdout, elr_grammar:first_symbol(_.symbol_table["A"])):write("\n")

grammar.first_table = elr_grammar:first()

local set_of_items, transitions = grammar:lalr1_items()
local data, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
writer:write_conflicts(io.stdout, conflicts, true)
writer:write_table(assert(io.open("test.html", "w")), data):close()
