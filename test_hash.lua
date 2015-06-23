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

local hash = require "dromozoa.parser.hash"
local murmur_hash3 = require "dromozoa.parser.murmur_hash3"

assert(murmur_hash3("", 0) == 0)
assert(murmur_hash3("a", 0) == 1009084850)
assert(murmur_hash3("ab", 0) == 2613040991)
assert(murmur_hash3("abc", 0) == 3017643002)
assert(murmur_hash3("abcd", 0) == 1139631978)
assert(murmur_hash3("abcde", 0) == 3902511862)
assert(murmur_hash3("abcdef", 0) == 1635893381)
assert(murmur_hash3("abcdefg", 0) == 2285673222)
assert(murmur_hash3("abcdefgh", 0) == 1239272644)
assert(murmur_hash3("abcdefghi", 0) == 1108608752)

assert(hash(true) == hash(true))
assert(hash(false) ~= hash(0))
assert(hash(false) ~= hash(""))
assert(hash(false) ~= hash(true))
assert(hash(false) ~= hash({}))

assert(hash({}) == hash({}))
assert(hash({ "foo", "bar", "baz" }) == hash({ "foo", "bar", "baz" }))
assert(hash({ "foo", "bar", "baz" }) ~= hash({ "foo", { "bar", "baz" } }))
assert(hash({ "foo", "bar", "baz" }) ~= hash({ "foo", { "bar", { "baz" } } }))

assert(hash(42) ~= hash("42"))
