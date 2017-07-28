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

local lexer = require "dromozoa.parser.builder.lexer"

local super = lexer
local class = {}
local metatable = {
  __index = class;
  __call = lexer.metatable.__call;
}
class.metatable = metatable

function class:_(that)
  local items = self.items
  if type(that) == "string" then
    items[#items + 1] = {
      name = that;
      pattern = class.super.pattern(that);
      actions = {};
    }
  else
    items[#items + 1] = {
      pattern = that;
      actions = {};
    }
  end
  return self
end

return setmetatable(class, {
  __index = super;
  __call = function (_, name)
    return setmetatable({ type = "regexp_lexer", name = name, items = {} }, metatable)
  end;
})
