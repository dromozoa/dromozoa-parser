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
local precedence = require "dromozoa.parser.builder.precedence"
local production = require "dromozoa.parser.builder.production"
local scanner = require "dromozoa.parser.builder.scanner"

local class = {}

function class.new()
  return {
    scanners = {
      scanner();
      n = 1;
    };
    precedence = precedence();
    productions = sequence();
  }
end

function class:scanner(name)
  local scanners = self.scanners
  if name == nil then
    return scanners[1]
  end
  local that = scanners[name]
  if that == nil then
    that = scanner()
    local n = scanners.n + 1
    scanners[n] = that
    scanners[name] = that
    scanners.n = n
  end
  return that
end

function class:lit(literal)
  return self:scanner():lit(literal)
end

function class:pat(pattern)
  return self:scanner():pat(pattern)
end

function class:left(name)
  return self.precedence:left(name)
end

function class:right(name)
  return self.precedence:right(name)
end

function class:noassoc(name)
  return self.precedence:noassoc(name)
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  return production(self, name)
end

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
