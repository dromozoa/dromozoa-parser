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
local error_message = require "dromozoa.parser.error_message"

local P = builder.pattern
local R = builder.range
local S = builder.set

local _ = builder()

_:lexer()
  :_ (S" \r\n\t\v\f"^"+") :skip()
  :_ "{"
  :_ "}"
  :_ "["
  :_ "]"
  :_ ":"
  :_ ","
  :_ (P[["]] * (-S[[\"]] + P[[\]] * P(1))^"*" * P[["]]) :as "string"
  :_ (P"0" + R"19" * R"09"^"*") :as "integer"
  :_ "/*" "*/" :hold() :call "block_comment" :skip()

_:search_lexer "block_comment"
  :when() :ret() :skip()
  :otherwise() :skip()

local lexer = _:build()

local file = "test.lua"
local source = [[
[
  42,
  "foo",
  3.14
]
]]

local result, message, i = lexer(source)
assert(not result)
print(error_message(message, source, i, "test.txt"))
assert(error_message(message, source, i, "test.txt") == "test.txt:4:4: lexer error")
