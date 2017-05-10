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

function class.new()
  return {
    map = {};
    precedence = 0
  }
end

function class:left(name)
  local precedence = self.precedence + 1
  self.precedence = precedence
  self.associativity = "left"
  return self(name)
end

function class:right(name)
  local precedence = self.precedence + 1
  self.precedence = precedence
  self.associativity = "right"
  return self(name)
end

function class:nonassoc(name)
  local precedence = self.precedence + 1
  self.precedence = precedence
  self.associativity = "nonassoc"
  return self(name)
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  self.map[name] = {
    precedence = self.precedence;
    associativity = self.associativity;
  }
  return self
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
