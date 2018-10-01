-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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
local metatable = { __index = class }

function class:_(name)
  local items = self.items
  items[#items + 1] = {
    head = self.head;
    body = { name };
    attribute_actions = {};
  }
  return self
end

function class:prec(name)
  local items = self.items
  items[#items].precedence = name
  return self
end

-- TODO deprecate
function class:collapse()
  local items = self.items
  items[#items].semantic_action = { 1 }
  return self
end

function class:attr(a, b, c)
  local items = self.items
  local attribute_actions = items[#items].attribute_actions
  if type(a) == "number" then
    if c == nil then
      c = true
    end
    attribute_actions[#attribute_actions + 1] = { 2, a, b, c }
  else
    if b == nil then
      b = true
    end
    attribute_actions[#attribute_actions + 1] = { 1, a, b }
  end
  return self
end

function metatable:__call(...)
  local items = self.items
  if type(...) == "string" then
    local body = items[#items].body
    body[#body + 1] = ...
  else
    local t = ...
    local k, v = next(t)
    if v then
      if type(v) == "table" then
        items[#items].semantic_action = { 2, k, v }
      else
        items[#items].semantic_action = { 3, t }
      end
    else
      items[#items].semantic_action = { 3, {} }
    end
  end
  return self
end

function metatable:__call(a, b, c)
  local items = self.items
  if type(a) == "string" then
    local body = items[#items].body
    body[#body + 1] = a
  else
    local k, v = next(a)
    if v then
      if type(v) == "table" then
        items[#items].semantic_action = { 2, k, v }
      else
        items[#items].semantic_action = { 3, a }
      end
    else
      items[#items].semantic_action = { 3, {} }
    end
  end
  return self
end

return setmetatable(class, {
  __call = function (_, items, name)
    return setmetatable({ items = items, head = name }, metatable)
  end;
})
