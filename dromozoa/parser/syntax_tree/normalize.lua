-- Copyright (C) 2015 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local apply = require "dromozoa.commons.apply"
local sequence = require "dromozoa.commons.sequence"

local class = {}

function class.new(this)
  return {
    this = this;
  }
end

function class:discover_node(u)
  local tag = u[1]
  if tag == "|" or tag == "concat" then
    u.bodies = sequence()
  end
end

function class:finish_edge(u, v)
  local tag = u[1]
  if tag == "|" or tag == "concat" then
    u.bodies:push(v.ref)
  end
end

function class:apply()
  local this = self.this

  local map = {}
  for u in this:start():each_child() do
    local name = u[2]
    local v = map[name]
    if v == nil then
      map[name] = apply(u:each_child())
    else
      for w in apply(u:each_child()):each_child() do
        v:append_child(w:remove())
      end
      u:remove():delete(true)
    end
  end

  return this
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, this)
    return setmetatable(class.new(this), metatable)
  end;
})
