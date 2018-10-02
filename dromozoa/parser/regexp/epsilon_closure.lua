-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local function visit(epsilons1, epsilons2, epsilon_closure, u)
  local v = epsilons1[u]
  if v then
    if not epsilon_closure[v] then
      epsilon_closure[v] = true
      visit(epsilons1, epsilons2, epsilon_closure, v)
    end
    local v = epsilons2[u]
    if v and not epsilon_closure[v] then
      epsilon_closure[v] = true
      visit(epsilons1, epsilons2, epsilon_closure, v)
    end
  end
end

return function (this, epsilon_closures, u)
  local epsilon_closure = epsilon_closures[u]
  if not epsilon_closure then
    epsilon_closure = { [u] = true }
    epsilon_closures[u] = epsilon_closure
    local epsilons = this.epsilons
    visit(epsilons[1], epsilons[2], epsilon_closure, u)
  end
  return epsilon_closure
end
