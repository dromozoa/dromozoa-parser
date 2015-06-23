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

local function construct(_front, _back, _data)
  local self = {}

  function self:front()
    return _data[_front]
  end

  function self:back()
    return _data[_back]
  end

  function self:push_front(value)
    local i = _front - 1
    _front = i
    _data[i] = value
  end

  function self:push_back(value)
    local i = _back + 1
    _back = i
    _data[i] = value
  end

  function self:pop_front()
    local i = _front
    local value = _data[i]
    _front = i + 1
    _data[i] = nil
    return value
  end

  function self:pop_back()
    local i = _back
    local value = _data[i]
    _back = i - 1
    _data[i] = nil
    return value
  end

  function self:empty()
    return _back < _front
  end

  function self:size()
    return _back - _front + 1
  end

  return self
end

return function ()
  return construct(1, 0, {})
end
