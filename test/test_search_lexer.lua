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
local symbol_value = require "dromozoa.parser.symbol_value"

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

local source = [[
[====[test]====]
[====[
foo [===[ bar ]===] baz
]====]
]]

local result = assert(lexer(source))
assert(symbol_value(result[1]) == "test")
assert(symbol_value(result[2]) == "\nfoo [===[ bar ]===] baz\n")
assert(result[3][0] == 1)

local data = {}
for i = 1, #result do
  local item = result[i]
  data[#data + 1] = source:sub(item.p, item.j)
end
print(#source, result[#result].p, result[#result].i, result[#result].j, ("%q"):format(data[#data]))
io.write(table.concat(data))
assert(table.concat(data) == source)
