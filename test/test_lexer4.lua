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
local symbol_value = require "dromozoa.parser.symbol_value"

local RE = builder.regexp
local _ = builder()

_:lexer()
  :_ (RE[[\s+]]) :skip()
  :_ ("[[" * (RE[[.*]] - RE[[.*\]\].*]]) * "]]") :sub(3, -3) :as "long_string" :normalize_eol()

local lexer = _:build()

local function check(eol)
  local source = "[[" .. eol .. "ABC" .. eol .. eol .. eol .. eol .. "DEF" ..eol .. "]]" .. eol
  local result = assert(lexer(source))
  local value = symbol_value(result[1])
  assert(value == "ABC\n\n\n\nDEF\n")
end

check "\r"
check "\n"
check "\r\n"
check "\n\r"
