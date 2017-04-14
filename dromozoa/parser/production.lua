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

local sequence = require "dromozoa.commons.sequence"

local class = {}

function class.new(head, ...)
  return {
    head = head;
    body = sequence():push(...);
  }
end

function class:write(out)
  self.head:write(out)
  out:write(" &\\to&")
  for s in self.body:each() do
    out:write(" \\  ")
    s:write(out)
  end
  return out
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, head, ...)
    return setmetatable(class.new(head, ...), class.metatable)
  end;
})
