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

local encode_string = require "dromozoa.parser.dumper.encode_string"

local source = "foo\a\b\f\n\r\t\v\\\"\'\000\127\255bar日本語"

-- print(("%q"):format(source))
print(encode_string(source))

local loadstring = loadstring or load
local chunk = assert(loadstring("return " .. encode_string(source)))
assert(chunk() == source)
