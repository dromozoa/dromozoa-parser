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

local _ = builder()

_ :lit "+"
  :lit "-"
  :lit "*"
  :lit "/"
  :lit "("
  :lit ")"
  :pat "[%a_][%w_]*" :as "id"

_ :left "+" "-"
  :left "*" "/"
  :right "UMINUS"

_ "expression"
  :_ "expression" "+" "term"
  :_ "expression" "-" "term"
  :_ "term"

_ "term"
  :_ "term" "*" "factor"
  :_ "term" "/" "factor"
  :_ "factor"

_ "factor"
  :_ "(" "expression" ")"
  :_ "-" "id" :prec "UMINUS"
  :_ "id"

-- _"expression"
--     :_(_"expression", "+", _"term")
--     :_(_"expression", "-", _"term")
--     :_(_"term")
-- _"term"
--     :_(_"term", "*", _"factor")
--     :_(_"term", "/", _"factor")
--     :_(_"factor")
-- _"factor"
--     :_("(", _"expression", ")")
--     :_("id")
-- local g = _()

print(dumper.encode(_, { pretty = true, stable = true }))
print(dumper.encode(_:build(), { pretty = true, stable = true }))
