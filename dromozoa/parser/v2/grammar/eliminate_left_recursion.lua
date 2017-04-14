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

local empty = require "dromozoa.commons.empty"
local equal = require "dromozoa.commons.equal"
local keys = require "dromozoa.commons.keys"
local sequence = require "dromozoa.commons.sequence"

local function eliminate_immediate_left_recursion(prods, head1, bodies)
  local head2 = { head1 }
  local bodies1 = sequence()
  local bodies2 = sequence()
  for body in bodies:each() do
    if equal(body[1], head1) then
      bodies2:push(sequence():copy(body, 2):push(head2))
    else
      bodies1:push(sequence():copy(body):push(head2))
    end
  end
  if not empty(bodies2) then
    bodies2:push(sequence())
    prods[head1] = bodies1
    prods[head2] = bodies2
  end
end

return function (this)
  local prods = this.prods
  local heads = keys(prods)
  for i = 1, #heads do
    local head1 = heads[i]
    local bodies1 = prods[head1]
    for j = 1, i - 1 do
      local head2 = heads[j]
      local bodies2 = prods[head2]
      local bodies = sequence()
      for body1 in bodies1:each() do
        if equal(body1[1], head2) then
          for body2 in bodies2:each() do
            bodies:push(sequence():copy(body2):copy(body1, 2))
          end
        else
          bodies:push(body1)
        end
      end
      bodies1 = bodies
    end
    eliminate_immediate_left_recursion(prods, head1, bodies1)
  end
  return this
end
