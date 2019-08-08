-- Copyright (C) 2017-2019 Tomoyuki Fujimori <moyu@dromozoa.com>
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

function class:substitute(repl)
  local items = self.items
  local actions = items[#items].actions
  local t = type(repl)
  if t == "number" or t == "string" then
    actions[#actions + 1] = { 6, tostring(repl) }
  else
    error(("unsupported repl of type %q"):format(t))
  end
  return self
end

function class:hold()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 7 }
  return self
end

function class:mark()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 8 }
  return self
end

function class:sub(i, j)
  if not j then
    j = -1
  end
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 9, i, j }
  return self
end

function class:int(base)
  if not base then
    base = 10
  end
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 10, base }
  return self
end

function class:char()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 11 }
  return self
end

function class:join(head, tail)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 12, head, tail }
  return self
end

function class:utf8(i, j, k, l)
  if not j then
    j = -1
  end
  if not l then
    l = -1
  end
  local items = self.items
  local actions = items[#items].actions
  if k then
    actions[#actions + 1] = { 14, i, j, k, l }
  else
    actions[#actions + 1] = { 13, i, j }
  end
  return self
end

function class:add(value)
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 15, value }
  return self
end

function class:normalize_eol()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 16 }
  return self
end

function class:increment_eol()
  local items = self.items
  local actions = items[#items].actions
  actions[#actions + 1] = { 17 }
  return self
end

return class
