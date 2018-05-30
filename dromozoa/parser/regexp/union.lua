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

local merge = require "dromozoa.parser.regexp.merge"

return function (this, that)
  local this, that = merge(this, that)

  local max_state = this.max_state + 1
  local epsilons = this.epsilons
  local accept_states = this.accept_states

  epsilons[1][max_state] = this.start_state
  epsilons[2][max_state] = that.start_state

  for u, accept in pairs(that.accept_states) do
    accept_states[u] = accept
  end

  this.max_state = max_state
  this.start_state = max_state
  return this
end
