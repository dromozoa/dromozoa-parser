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

function class:find(key)
  local n = #key
  local map = self[n]
  if not map then
    return
  end
  for i = 1, n - 1 do
    map = map[key[i]]
    if not map then
      return
    end
  end
  return map[key[n]]
end

function class:insert(key, value)
  local n = #key
  local map = self[n]
  if not map then
    map = {}
    self[n] = map
  end
  for i = 1, n - 1 do
    local k = key[i]
    local m = map[k]
    if not m then
      m = {}
      map[k] = m
    end
    map = m
  end
  map[key[n]] = value
end

local metatable = {
  __index = class;
}
class.metatable = metatable

return setmetatable(class, {
  __call = function ()
    return setmetatable({}, metatable)
  end;
})
