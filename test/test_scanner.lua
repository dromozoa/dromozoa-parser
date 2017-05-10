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
local scanners = require "dromozoa.parser.builder.scanners"

local _ = scanners()

_"main"
  :pat "%s+" :_"ignore"
  :lit "*"
  :lit "+"
  :lit "("
  :lit ")"
  :pat "[1-9]%d*" :as "integer"
  :lit "\"" :call "string"
  :lit "abc"
  :pat "[a-z]+" :as "identifier"

_"string"
  :pat "\"" :_"return"
  :lit "\\\""
  :pat "[^\\\"]+"

local s, t = _()
print(dumper.encode(s, { pretty = true, stable = true }))

local data = [[
( 17 + 23 * 37 ) + "abc\"def" abc abcd
]]
local position = 1
while true do
  local symbol, i, j = s(data, position)
  print(symbol, t[symbol], i, j, data:sub(i, j))
  if symbol == 1 then
    break
  end
  position = j + 1
end
