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

function class:left(name)
  return self.builder:left(name)
end

function class:right(name)
  return self.builder:right(name)
end

function class:nonassoc(name)
  return self.builder:nonassoc(name)
end

local metatable = {
  __index = class;
}
class.metatable = metatable

function metatable:__call(name)
  local items = self.items
  items[#items + 1] = name
  return self
end

return setmetatable(class, {
  __call = function (_, builder, items)
    return setmetatable({ builder = builder, items = items }, metatable)
  end;
})
