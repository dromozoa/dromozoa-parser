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

function class:GETUPVAL(a, b)
  local R = self.R
  local U = self.U
  while true do
    local u = U[b]
    local id, in_stack = u[1], u[2]
    if in_stack then
      self.R[a] = R.R[id]
      break
    else
      U = R.U
      R = R.R
      b = id
    end
  end
end

function class:SETUPVAL(a, b)
  local R = self.R
  local U = self.U
  while true do
    local u = U[a]
    local id, in_stack = u[1], u[2]
    if in_stack then
      R.R[id] = self:get(b)
      break
    else
      U = R.U
      R = R.R
      a = id
    end
  end
end

function class:CALL(a, b)
  local f = self:get(a)
  if type(f) == "function" then
    if b == 1 then
      f()
    else
      f(table.unpack(self.R, a + 1, a + b - 1))
    end
  else
    assert(type(f) == "table")
    local K = self.K
    local R = self.R
    local U = self.U
    local proto = f.proto
    self.K = proto.K
    self.R = {
      R = R;
      U = U;
    }
    self.U = proto.U
    local f = proto.codes
    if b == 1 then
      f()
    else
      f(table.unpack(R, a + 1, a + b - 1))
    end
    self.K = K
    self.R = R
    self.U = U
  end
end

function class:args(n, ...)
  local R = self.R
  for i = 1, n do
    R[i - 1] = select(i, ...)
  end
end

function class:CLOSURE(a, b)
  self.R[a] = {
    proto = self.protos[b];
    R = self.R;
    U = self.U;
  }
end

function class:NEWTABLE(a)
  self.R[a] = {}
end

function class:SETTABLE(a, b, c)
  self:get(a)[self:get(b)] = self:get(c)
end

function class:GETTABLE(a, b, c)
  self.R[a] = self:get(b)[self:get(c)]
end

return setmetatable(class, {
  __call = function ()
    return setmetatable({
      K = {};
      R = {};
      U = {};
      ENV = {
        print = print;
      };
      protos = {};
    }, metatable)
  end;
})
