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

function class.new(productions, name)
  return {
    productions = productions;
    head = name;
  }
end

function class:_(name)
  self.productions:push({
    head = self.head;
    body = sequence():push(name);
  })
  return self
end

function class:prec(name)
  self.productions:top().precedence = name
  return self
end

class.metatable = {
  __index = class;
}

function class.metatable:__call(name)
  self.productions:top().body:push(name)
  return self
end

return setmetatable(class, {
  __call = function (_, productions, name)
    return setmetatable(class.new(productions, name), class.metatable)
  end;
})
