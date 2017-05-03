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

local ipairs = require "dromozoa.commons.ipairs"

local class = {}

function class.new()
  return {
    n = 0;
    map = {};
  }
end

function class:symbol(name)
  local map = self.map
  local id = map[name]
  if id == nil then
    id = self.n + 1
    self.n = id
    self[id] = name
    map[name] = id
  end
  return id
end

function class:max()
  return self.n
end

function class:each()
  return coroutine.wrap(function ()
    for id, name in ipairs(self) do
      coroutine.yield(id, name)
    end
  end)
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
