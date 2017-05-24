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
local regexp_writer = require "dromozoa.parser.regexp_writer"

local _ = builder()
local P = builder.P
local R = builder.R
local S = builder.S

_:scanner ()
  :pat(S" \t\n\v\f\r"^"+") :ignore()
  :lit "*"
  :lit "+"
  :lit "("
  :lit ")"
  :pat(R"09"^"+") :as "integer"
  :lit '"' :call "string"
  :lit "r"
  :pat(R"az"^"+") :as "identifier"

_:scanner "string"
  :lit '"' :ret()
  :lit '\\"'
  :pat((-S'\\"')^"+") :as "string_content"

_ "E"
  :_ "E" "*" "E"
  :_ "E" "+" "E"
  :_ "(" "E" ")"
  :_ "integer"
  :_ '"' "S" '"'
  :_ "r"
  :_ "identifier"

_ "S"
  :_ ()
  :_ "S" "string_content"
  :_ "\\\""
  :_ "string_content"

local scanner, grammar, symbol_names = _:build()
-- print(dumper.encode(scanner, { pretty = true, stable = true }))

for i = 1, #scanner.data do
  regexp_writer.write_automaton(assert(io.open("test-dfa" .. i .. ".dot", "w")), scanner.data[i].dfa):close()
end

local symbol_names = _.symbol_names

local source = [[
( 17 + 23 * 37 ) + "123\"456" ra r
]]
local position = 1
while true do
  local symbol, i, j = assert(scanner(source, position))
  print(symbol, symbol_names[symbol], i, j, source:sub(i, j))
  if symbol == 1 then
    break
  end
  position = j + 1
end
