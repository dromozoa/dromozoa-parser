-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local identity_generator = require "dromozoa.parser.identity_generator"

local tokens = identity_generator()
assert(tokens.TK_NUMBER == 1)
assert(tokens.TK_STRING == 2)
assert(tokens.TK_BOOLEAN == 3)
assert(#tokens == 3)
assert(tokens.TK_NUMBER == 1)
assert(tokens.TK_STRING == 2)
assert(tokens.TK_BOOLEAN == 3)
assert(#tokens == 3)
assert(tokens[1] == "TK_NUMBER")
assert(tokens[2] == "TK_STRING")
assert(tokens[3] == "TK_BOOLEAN")
