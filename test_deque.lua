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

local deque = require "dromozoa.parser.deque"

local q = deque()

q:push_back(1)
q:push_back(2)
q:push_back(3)
assert(q:size() == 3)
assert(q:front() == 1)
assert(q:back() == 3)

q:push_front(4)
q:push_front(5)
q:push_front(6)
assert(q:size() == 6)
assert(q:front() == 6)
assert(q:back() == 3)

local q2 = q:clone()

assert(q:pop_front() == 6)
assert(q:pop_back() == 3)
assert(q:size() == 4)
assert(q:front() == 5)
assert(q:back() == 2)

assert(q2:size() == 6)
assert(q2:front() == 6)
assert(q2:back() == 3)
