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

local function precedence(self, name, is_left)
  local precedence = self.precedence + 1
  self.precedence = precedence
  self.is_left = is_left
  return self(name)
end

local class = {}

function class.new()
  return {
    items = sequence();
    table = {};
    precedence = 0
  }
end

function class:left(name)
  return precedence(self, name, true)
end

function class:right(name)
  return precedence(self, name)
end

function class:nonassoc(name)
  return precedence(self, name)
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  local table = self.table
  if table[name] ~= nil then
    error(("precedence %q already defined"):format(name))
  end
  local item = {
    name = name;
    precedence = self.precedence;
    is_left = self.is_left;
  }
  self.items:push(item)
  table[name] = item
  return self
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
