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

function class.new(builder, items)
  return {
    builder = builder;
    items = items;
  }
end

function class:left(name)
  return self.builder:left(name)
end

function class:right(name)
  return self.builder:right(name)
end

function class:nonassoc(name)
  return self.builder:nonassoc(name)
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  local items = self.items
  items[#items + 1] = name
  return self
end

return setmetatable(class, {
  __call = function (_, builder, items)
    return setmetatable(class.new(builder, items), class.metatable)
  end;
})
