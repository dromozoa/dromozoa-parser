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
local count_position = require "dromozoa.parser.count_position"

local source = [[
123456789
123456789
123456789
]]

assert(equal({ count_position(source,  1) }, { 1,  1 }))
assert(equal({ count_position(source,  5) }, { 1,  5 }))
assert(equal({ count_position(source, 10) }, { 1, 10 }))
assert(equal({ count_position(source, 11) }, { 2,  1 }))
assert(equal({ count_position(source, 15) }, { 2,  5 }))
assert(equal({ count_position(source, 20) }, { 2, 10 }))
assert(equal({ count_position(source, 21) }, { 3,  1 }))
assert(equal({ count_position(source, 25) }, { 3,  5 }))
assert(equal({ count_position(source, 30) }, { 3, 10 }))
assert(equal({ count_position(source, 31) }, {}))
assert(equal({ count_position(source, 32) }, {}))
