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

local json = require "dromozoa.commons.json"
local builder = require "dromozoa.parser.builder_v2"
local regexp = require "dromozoa.parser.regexp"

local P = builder.pattern
local R = builder.range
local S = builder.set

local _ = builder()

_:lexer()
  :_ (S" \r\n\t\v\f"^"+") :skip()
  :_ "*"
  :_ "+"
  :_ "("
  :_ ")"
  :_ (R"19" * R"09"^"*") :as "integer"
  :_ '"' :call "string"

_:lexer "string"
  :_ '"' :ret()
  :_ '\\"'
  :_ (R"09"^"+") :as "integer"
  :_ ((-S'\\"')^"+") :as "string_content"

local lexer = _:build()
-- print(json.encode(_.lexers, { pretty = true, stable = true }))
-- print(json.encode(data, { pretty = true, stable = true }))
_.lexers[1].automaton:write_graphviz(assert(io.open("test-dfa1.dot", "w"))):close()
_.lexers[2].automaton:write_graphviz(assert(io.open("test-dfa2.dot", "w"))):close()

local s = [[
12 + 34 * 56 "test" "\"foo\""
]]

local position = 1
while true do
  local symbol, i, j = assert(lexer(s, position))
  print(symbol, s:sub(i, j))
  if symbol == 1 then
    break
  end
  position = j + 1
end
