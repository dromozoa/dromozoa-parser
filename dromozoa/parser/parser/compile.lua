-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local dump = require "dromozoa.parser.dump"
local runtime = require "dromozoa.parser.parser.runtime"

return function (self, out)
  out:write "local execute = (function ()\n"
  out:write(runtime)
  out:write "end)()\n"
  out:write "local metatable = { __call = execute }\n"
  local root = dump(out, self)
  out:write("local root = setmetatable(", root, ", metatable)\n")
  out:write "return function() return root end\n"
  return out
end
