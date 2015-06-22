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

local aformat = require "dromozoa.parser.aformat"

local DBL_MAX = 1.7976931348623157e+308
local DBL_DENORM_MIN = 4.9406564584124654e-324
local DBL_MIN = 2.2250738585072014e-308
local DBL_EPSILON = 2.2204460492503131e-16

assert(aformat(42) == "0x1.5000000000000p+5")
assert(aformat(DBL_MAX) == "0x1.fffffffffffffp+1023")
assert(aformat(DBL_DENORM_MIN) == "0x1.0000000000000p-1074")
assert(aformat(DBL_MIN) == "0x1.0000000000000p-1022")
assert(aformat(DBL_EPSILON) == "0x1.0000000000000p-52")
assert(aformat(math.pi) == "0x1.921fb54442d18p+1")
assert(aformat(0) == "0x0.0000000000000p+0")
assert(aformat(-1 / math.huge) == "-0x0.0000000000000p+0")
assert(aformat(math.huge) == "inf")
assert(aformat(-math.huge) == "-inf")
assert(aformat(0 / 0) == "nan")
