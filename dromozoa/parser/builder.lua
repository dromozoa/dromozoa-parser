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
local build = require "dromozoa.parser.builder.build"
local lexer = require "dromozoa.parser.builder.lexer"
local pattern = require "dromozoa.parser.builder.pattern"
local precedence = require "dromozoa.parser.builder.precedence"
local production = require "dromozoa.parser.builder.production"
local regexp = require "dromozoa.parser.builder.regexp"
local regexp_lexer = require "dromozoa.parser.builder.regexp_lexer"
local search_lexer = require "dromozoa.parser.builder.search_lexer"

local class = {
  atom = atom;
  range = atom.range;
  set = atom.set;
}
local metatable = {
  __index = class;
}
class.metatable = metatable

lexer.super = class
pattern.super = class
regexp.super = class

function class.pattern(that)
  local t = type(that)
  if t == "number" then
    if that == 1 then
      return atom.any()
    else
      local items = {}
      for i = 1, that do
        items[i] = atom.any()
      end
      return pattern.concat(items)
    end
  elseif t == "string" then
    if #that == 1 then
      return atom.char(that)
    else
      local items = {}
      for i = 1, #that do
        items[i] = atom.char(that:sub(i, i))
      end
      return pattern.concat(items)
    end
  else
    return that
  end
end

function class.regexp(that)
  return regexp.parse(that)
end

function class:lexer(name)
  return self:regexp_lexer(name)
end

function class:regexp_lexer(name)
  local lexers = self.lexers
  if name == nil then
    return lexers[1]
  else
    local lexer = regexp_lexer(name)
    lexers[#lexers + 1] = lexer
    return lexer
  end
end

function class:search_lexer(name)
  local lexers = self.lexers
  local lexer = search_lexer(name)
  lexers[#lexers + 1] = lexer
  return lexer
end

function class:precedence(name, associativity)
  local precedences = self.precedences
  local items = {}
  precedences[#precedences + 1] = {
    associativity = associativity;
    items = items
  }
  return precedence(self, items)(name)
end

function class:left(name)
  return self:precedence(name, 1)
end

function class:right(name)
  return self:precedence(name, 2)
end

function class:nonassoc(name)
  return self:precedence(name, 3)
end

function class:build(start_name)
  return build(self, start_name)
end

function metatable:__call(name)
  return production(self.productions, name)
end

return setmetatable(class, {
  __call = function ()
    return setmetatable({
      lexers = { regexp_lexer() };
      precedences = {};
      productions = { true };
    }, metatable)
  end;
})
