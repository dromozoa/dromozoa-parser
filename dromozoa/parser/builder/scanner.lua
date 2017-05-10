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
    rules = sequence();
  }
end

function class:lit(literal)
  self.rules:push({
    name = literal;
    match = "^" .. literal:gsub("%W", "%%%0");
  })
  return self
end

function class:pat(pattern)
  self.rules:push({
    name = pattern;
    match = "^" .. pattern;
  })
  return self
end

function class:as(name)
  self.rules:top().name = name
  return self
end

function class:ignore()
  self.rules:top().action = { "ignore" }
  return self
end

function class:call(name)
  self.rules:top().action = { "call", name }
  return self
end

function class:ret()
  self.rules:top().action = { "ret" }
  return self
end

function class:build(terminal_symbols, env)
  local data = sequence()
  for rule in self.rules:each() do
    rule.symbol = terminal_symbols:symbol(rule.name)
    local action = rule.action
    if action and action[1] == "call" then
      action[2] = assert(env[action[2]])
    end
    data:push(rule)
  end
  return data
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
