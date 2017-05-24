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

local start_scanner = 1
local marker_end = 1

local class = {}

function class.new(data)
  return {
    data = data;
    scanners = sequence():push(start_scanner);
  }
end

function class:scan(s, init)
  if #s < init then
    return marker_end, init, init
  end

  local data = self.data
  local scanners = self.scanners

  local scanner = data[scanners:top()]
  local dfa = scanner.dfa
  local transitions = dfa.transitions
  local accept_states = dfa.accept_states
  local actions = scanner.actions

  local state = dfa.start_state
  for i = init, #s + 1 do
    local n
    if i <= #s then
      local c = s:byte(i)
      n = transitions[c][state]
    end
    if n == nil then
      local a = accept_states[state]
      if a then
        local action = actions[a]
        if action then
          if action == 1 then -- ignore
            return self:scan(s, i)
          elseif action == 2 then -- ret
            scanners:pop()
          else -- call
            scanners:push(action - 2)
          end
        end
        return a, init, i - 1
      else
        return nil, "scanner error", init
      end
    else
      state = n
    end
  end
end

class.metatable = {
  __index = class;
  __call = class.scan;
}

return setmetatable(class, {
  __call = function (_, data)
    return setmetatable(class.new(data), class.metatable)
  end;
})
