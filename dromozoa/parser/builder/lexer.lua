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

local class = {}

function class.new(name)
  return {
    name = name;
    items = {};
  }
end

function class:_(that)
  local items = self.items
  if type(that) == "string" then
    items[#items + 1] = {
      name = that;
      pattern = class.super.pattern(that);
      action = 1;
      operator = 1;
    }
  else
    items[#items + 1] = {
      pattern = that;
      action = 1;
      operator = 1;
    }
  end
  return self
end

function class:as(name)
  local items = self.items
  items[#items].name = name
  return self
end

function class:skip()
  local items = self.items
  items[#items].action = 2
  return self
end

function class:call(label)
  local items = self.items
  local item = items[#items]
  item.operator = 2
  item.operand = label
  return self
end

function class:ret()
  local items = self.items
  items[#items].operator = 3
  return self
end

local metatable = {
  __index = class;
}
class.metatable = metatable

return setmetatable(class, {
  __call = function (_, name)
    return setmetatable(class.new(name), metatable)
  end;
})
