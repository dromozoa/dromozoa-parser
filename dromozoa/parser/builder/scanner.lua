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

local class = {}

function class.new()
  return {
    items = sequence();
  }
end

function class:lit(literal)
  local item = {
    name = literal;
    match = "^" .. literal:gsub("%W", "%%%0");
  }
  self.items:push(item)
  return self
end

function class:pat(pattern)
  local item = {
    name = pattern;
    match = "^" .. pattern;
  }
  self.items:push(item)
  return self
end

function class:as(name)
  self.items:top().name = name
  return self
end

function class:nullary_action(action)
  self.items:top().action = { action }
  return self
end

function class:call(name)
  self.items:top().action = { "call", name }
  return self
end

function class:build(terminal_symbols, env)
  local data = sequence()
  for item in self.items:each() do
    item.symbol = terminal_symbols:symbol(item.name)
    local action = item.action
    if action and action[1] == "call" then
      action[2] = assert(env[action[2]])
    end
    data:push(item)
  end
  return data
end

class._ = class.nullary_action

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
