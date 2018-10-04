-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local RE = builder.regexp

local result, message = pcall(function ()
  RE "a{0,1}b{1,0}"
end)
assert(not result)
print(message)
assert(message:find "<unknown>:1:8: syntax error")

local result, message = pcall(function ()
  RE "aaaa["
end)
assert(not result)
print(message)
assert(message:find "<unknown>:eof: lexer error")

local result, message = pcall(function ()
  RE "aaaa("
end)
assert(not result)
print(message)
assert(message:find "<unknown>:eof: parser error")
