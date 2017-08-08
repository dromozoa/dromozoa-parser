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

function class:as(name)
  local items = self.items
  items[#items].name = name
  return self
end

function class:skip()
  local items = self.items
  local item = items[#items]
  item.skip = true
  local actions = item.actions
  actions[#actions + 1] = { 1 }
  return self
end

function class:push()
  local items = self.items
  local item = items[#items]
  item.skip = true
  local actions = item.actions
  actions[#actions + 1] = { 2 }
  return self
end

function class:concat()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 3 }
  return self
end

function class:call(label)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 4, label }
  return self
end

function class:ret()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 5 }
  return self
end

function class:hold()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 9 }
  return self
end

function class:mark()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 10 }
  return self
end

function class:sub(i, j)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 11, i, j }
  return self
end

function class:int(base)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 12, base }
  return self
end

function class:char()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 13 }
  return self
end

function class:join(before, after)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 14 }
  return self
end

function class:utf8(i, j)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 15, i, j }
  return self
end

function class:utf8_surrogate_pair(i1, j1, i2, j2)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 16, i1, j1, i2, j2 }
  return self
end

function class:add(x)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 17, x }
  return self
end

function metatable:__call(repl)
  local items = self.items
  local actions = items[#items].actions
  local t = type(repl)
  if t == "number" or t == "string" then
    actions[#actions + 1] = { 8, tostring(repl) }
  else
    error(("unsupported repl of type %q"):format(t))
  end
  return self
end

return class
