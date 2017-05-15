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

_ :pat "%s+" :ignore ()
  :pat "%a+" :as "id"
  :lit "+"
  :lit "*"
  :lit "("
  :lit ")"

-- left recursive
-- _ "E"
--   :_ "E" "+" "T"
--   :_ "T"
-- _ "T"
--   :_ "T" "*" "F"
--   :_ "F"
-- _ "F"
--   :_ "(" "E" ")"
--   :_ "id"

_ "E"
  :_ "T" "E'"
_ "E'"
  :_ "+" "T" "E'"
  :_ ()
_ "T"
  :_ "F" "T'"
_ "T'"
  :_ "*" "F" "T'"
  :_ ()
_ "F"
  :_ "(" "E" ")"
  :_ "id"

local scanner, grammar, writer = _:build()
print(dumper.encode(grammar, { pretty = true, stable = true }))

local _ = _.symbol_table
writer:write_first(io.stdout, grammar:first_symbol(_["F"])):write("\n") -- (, id
writer:write_first(io.stdout, grammar:first_symbol(_["T"])):write("\n") -- (, id
writer:write_first(io.stdout, grammar:first_symbol(_["E"])):write("\n") -- (, id
writer:write_first(io.stdout, grammar:first_symbol(_["E'"])):write("\n") -- +, epsilon
writer:write_first(io.stdout, grammar:first_symbol(_["T'"])):write("\n") -- *, epsilon
