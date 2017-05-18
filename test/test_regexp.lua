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
local regexp_builder = require "dromozoa.parser.regexp_builder"

local P = regexp_builder.P
local R = regexp_builder.R
local S = regexp_builder.S

-- [A-Z]|[13579]abcdef|(xyz)*
local p1 = R "AZaz09" + S "13579" * "abcdef" + P "xyz" ^0
-- [^a-z]^{1,2}
local p2 = (-R"AZ") ^{1,2}
-- (abc)?def
local p3 = P "abc" ^-1 * "def"

print(dumper.encode(p1, { pretty = true }))
