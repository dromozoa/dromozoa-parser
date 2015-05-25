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

local regexp = require "dromozoa.regexp"
local match = require "dromozoa.regexp.match"

local re_comment = regexp([[/\*]]):concat(regexp([[.*]]):difference([[.*\*/.*]])):concat([[\*/]])
local re_name = regexp("[[:alpha:]._][[:alnum:]._]*")
local re_literal = regexp([=['([^'\]|\\(['"?\abfnrtv]|[0-7]{1,3}|x[[:xdigit:]]+))']=])
local re_number = regexp("[[:digit:]]+")

re_comment:write_graphviz(assert(io.open("test-re_comment.dot", "w"))):close()
re_name:write_graphviz(assert(io.open("test-re_name.dot", "w"))):close()
re_literal:write_graphviz(assert(io.open("test-re_literal.dot", "w"))):close()
re_number:write_graphviz(assert(io.open("test-re_number.dot", "w"))):close()

print(arg[1])
print(match(re_literal:compile(), arg[1]))

