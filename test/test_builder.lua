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
local builder = require "dromozoa.parser.builder_v2"

local P = builder.pattern
local R = builder.range
local S = builder.set
-- local _ = builder()

local data = {
  -- P(1);
  P"a";
  P"a" + "c";
  "b" + P"z";
  P"a" * P"b";
  -- -P"1";
  -- -R"09azAZ";
  P"abc"^"+";
  P"a"^-4
}

print(dumper.encode(data, { pretty = true, stable = true}))
