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
  local result_item
  local result_j
  for item in scanner:each() do
    local i, j = s:find(item.pattern, init)
    if i == init then
      if result_j == nil then
        result_item = item
        result_j = j
      elseif result_j < j then
        result_item = item
        result_j = j
      end
    end
  end
  if result_item then
    local action = result_item.action
    if action == "ignore" then
      return self:scan(s, result_j + 1)
    elseif action == "call" then
      scanners:push(result_item.arguments[1])
    elseif action == "ret" then
      scanners:pop()
    end
    return result_item.symbol, init, result_j
  else
    return nil, "scanner error", init
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
