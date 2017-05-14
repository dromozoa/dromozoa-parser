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
local driver = require "dromozoa.parser.driver"

local source = ...

local _ = builder()

_ :lit "|"
  :lit "^"
  :lit "$"
  :pat "[^%^%.%[%$%(%)%|%*%+%?%{%\\]" :as "char"
  :pat "%\\[%^%.%[%$%(%)%|%*%+%?%{%\\]" :as "escaped_char"
  :lit "."
  :lit "("
  :lit ")"
  :lit "*"
  :lit "+"
  :lit "?"
  :lit "{" :call "dupl"
  :lit "[" :call "bracket"
  :lit "[^" :call "bracket"

_:scanner "dupl"
  :lit "}" :ret ()
  :pat "%d+" :as "DUP_COUNT"
  :lit ","

_:scanner "bracket"
  :lit "]" :ret ()
  :lit "-]" :ret ()
  :lit "--"
  :lit "-"
  :pat "[^%^%-%]]" :as "end_range_char"
  :pat "%[%=.-%=%]" :as "equivalence_class"
  :pat "%[%:.-%:%]" :as "character_class"
  :pat "%[%..-%.%]" :as "collating_symbol"

_ "extended_reg_exp"
  :_ "ERE_branch"
  :_ "extended_reg_exp" "|" "ERE_branch"

_ "ERE_branch"
  :_ "ERE_expression"
  :_ "ERE_branch" "ERE_expression"

_ "ERE_expression"
  :_ "one_char_or_coll_elem_ERE"
  :_ "^"
  :_ "$"
  :_ "(" "extended_reg_exp" ")"
  :_ "ERE_expression" "ERE_dupl_symbol"

_ "one_char_or_coll_elem_ERE"
  :_ "char"
  :_ "escaped_char"
  :_ "."
  :_ "bracket_expression"

_ "ERE_dupl_symbol"
  :_ "*"
  :_ "+"
  :_ "?"
  :_ "{" "DUP_COUNT" "}"
  :_ "{" "DUP_COUNT" "," "}"
  :_ "{" "DUP_COUNT" "," "DUP_COUNT" "}"

_ "bracket_expression"
  :_ "[" "expression_terms" "]"
  :_ "[" "expression_terms" "-]"
  :_ "[^" "expression_terms" "]"
  :_ "[^" "expression_terms" "-]"

_ "expression_terms"
  :_ "expression_term"
  :_ "expression_terms" "expression_term"

_ "expression_term"
  :_ "equivalence_class"
  :_ "character_class"
  :_ "end_range" "--"
  :_ "end_range" "-" "end_range"
  :_ "end_range"

_ "end_range"
  :_ "collating_symbol"
  :_ "end_range_char"

local scanner, grammar, writer = _:build()
local set_of_items, transitions = grammar:lalr1_items()
local data, conflicts = grammar:lr1_construct_table(set_of_items, transitions)
writer:write_conflicts(io.stdout, conflicts, true)
writer:write_table(assert(io.open("test.html", "w")), data):close()

local driver = driver(data)

local position = 1
while true do
  local symbol, i, j = scanner(source, position)
  print(symbol, writer.symbol_names[symbol], i, j, source:sub(i, j))
  if symbol == 1 then
    assert(driver:parse())
    break
  else
    assert(driver:parse(symbol, { value = source:sub(i, j) }))
  end
  position = j + 1
end

writer:write_tree(assert(io.open("test-tree.dot", "w")), driver.tree):close()

local out = assert(io.open("test-data.lua", "w"))
out:write("return ", dumper.encode(data), "\n")
out:close()
