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

local atom = require "dromozoa.parser.builder.atom"
local lexer = require "dromozoa.parser.builder.lexer"
local pattern = require "dromozoa.parser.builder.pattern"
local precedence = require "dromozoa.parser.builder.precedence"

local class = {
  range = atom.range;
  set = atom.set;
}

function class.new()
  return {
    lexers = { lexer() };
    precedence = precedence();
  }
end

function class.pattern(that)
  local t = type(that)
  if t == "number" then
    if that == 1 then
      return atom.any()
    else
      local any = atom.any()
      local items = {}
      for i = 1, that do
        items[i] = any
      end
      return pattern.concat(items)
    end
  elseif t == "string" then
    if #that == 1 then
      return atom.char(that)
    else
      local char = atom.char
      local items = {}
      for i = 1, #that do
        items[i] = char(that:sub(i, i))
      end
      return pattern.concat(items)
    end
  else
    return that
  end
end

function class:lexer(name)
  local lexers = self.lexers
  if name == nil then
    return lexers[1]
  else
    local lexer = lexer(name)
    lexers[#lexers + 1] = lexer
    return lexer
  end
end

function class:left(name)
  return self.precedence:left(name)
end

function class:right(name)
  return self.precedence:right(name)
end

function class:nonassoc(name)
  return self.precedence:nonassoc(name)
end

lexer.super = class
pattern.super = class

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
