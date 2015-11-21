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

local sequence = require "dromozoa.commons.sequence"

local class = {}

function class.new(this, that)
  return {
    this = this;
    that = that;
  }
end

function class:discover_node(u)
  local tag = u[1]
  if tag == "|" then
    u.bodies = sequence()
  elseif tag == "concat" then
    u.bodies = sequence():push(sequence())
  elseif tag == "ref" then
    u.bodies = sequence():push(sequence():push(u[2]))
  end
end

function class:finish_edge(u, v)
  local tag = u[1]
  if tag == "=" then
    u.bodies = v.bodies
  elseif tag == "|" then
    u.bodies:copy(v.bodies)
  elseif tag == "concat" then
    local ubodies = u.bodies
    local vbodies = v.bodies
    local bodies = sequence()
    for ubody in ubodies:each() do
      for vbody in vbodies:each() do
        bodies:push(sequence():copy(ubody):copy(vbody))
      end
    end
    u.bodies = bodies
  end
end

function class:apply()
  local this = self.this
  local that = self.that
  this:dfs(self)
  for u in this:start():each_child() do
    local head = u[2]
    local bodies = that[head]
    if bodies == nil then
      that[head] = sequence():copy(u.bodies)
    else
      bodies:copy(u.bodies)
    end
  end
  return that
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function (_, this, that)
    return setmetatable(class.new(this, that), metatable)
  end;
})
