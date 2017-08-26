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

local class = {}
local metatable = {
  __index = class;
}
class.metatable = metatable

function class:get(r)
  if r < 0 then
    return self.K[-r]
  else
    return self.R[r]
  end
end

function class:LOADBOOL(a, b)
  self.R[a] = b ~= 0
end

function class:LOADK(a, b)
  self.R[a] = self.K[-b]
end

function class:MOVE(a, b)
  self.R[a] = self:get(b)
end

function class:LOADNIL(a)
  self.R[a] = nil
end

function class:ADD(a, b, c)
  self.R[a] = self:get(b) + self:get(c)
end

function class:MUL(a, b, c)
  self.R[a] = self:get(b) * self:get(c)
end

function class:GETGLOBAL(a, b)
  self.R[a] = self.ENV[self:get(b)]
end

function class:CALL(a, b)
  local f = self:get(a)
  if b == 1 then
    f()
  else
    f(table.unpack(self.R, a + 1, a + b - 1))
  end
end

return setmetatable(class, {
  __call = function ()
    return setmetatable({
      K = {};
      R = {};
      ENV = {
        print = print;
      };
    }, metatable)
  end;
})
