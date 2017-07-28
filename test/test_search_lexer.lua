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

local equal = require "dromozoa.commons.equal"
local builder = require "dromozoa.parser.builder"

local P = builder.pattern
local R = builder.range
local S = builder.set

local _ = builder()

_:lexer()
  :_ (S" \r\n\t\v\f"^"+") :skip()
  :_ "[====[" "]====]" :hold() :call "search" :skip()

_:search_lexer "search"
  :when() :ret() :skip()
  :otherwise() :as "string_content"

local lexer = _:build()

local s = [[
[====[test]====]
[====[
foo [===[ bar ]===] baz
]====]
]]

local position = 1
local rs
local ri
local rj

local data = {}
repeat
  symbol, position, rs, ri, rj = assert(lexer(s, position))
  data[#data + 1] = { _.symbol_names[symbol], rs:sub(ri, rj) }
until symbol == 1

assert(equal(data, {
  { "string_content", "test" };
  { "string_content", "\nfoo [===[ bar ]===] baz\n" };
  { "$", "" };
}))
