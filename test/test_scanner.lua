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
local scanners = require "dromozoa.parser.scanners"

local _ = builder()

_ :pat "%s+" :ignore()
  :lit "*"
  :lit "+"
  :lit "("
  :lit ")"
  :pat "[0-9]%d*" :as "integer"
  :lit "\"" :as "LDQ" :call "string"
  :lit "r"
  :pat "[a-z]+" :as "identifier"

_:scanner "string"
  :lit "\"" :as "RDQ" :ret()
  :lit "\\\""
  :pat "[^\\\"]+" :as "string_content"

_ "E"
  :_ "E" "*" "E"
  :_ "E" "+" "E"
  :_ "(" "E" ")"
  :_ "integer"
  :_ "LDQ" "S" "RDQ"
  :_ "r"
  :_ "identifier"

_ "S"
  :_ ()
  :_ "S" "string_content"
  :_ "\\\""
  :_ "string_content"

local data = _:build()
print(dumper.encode(data.scanners, { pretty = true, stable = true }))
local s = scanners(data.scanners)

local source = [[
( 17 + 23 * 37 ) + "123\"456" ra r
]]
local position = 1
while true do
  local symbol, i, j = assert(s(source, position))
  print(symbol, data.symbols[symbol], i, j, source:sub(i, j))
  if symbol == 1 then
    break
  end
  position = j + 1
end
