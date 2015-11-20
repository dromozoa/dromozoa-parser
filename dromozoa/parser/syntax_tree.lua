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

local apply = require "dromozoa.commons.apply"
local clone = require "dromozoa.commons.clone"
local tree = require "dromozoa.tree"
local grammar = require "dromozoa.parser.grammar"
local builder = require "dromozoa.parser.syntax_tree.builder"
local graphviz_visitor = require "dromozoa.parser.syntax_tree.graphviz_visitor"
local normalize = require "dromozoa.parser.syntax_tree.normalize"
local to_grammar = require "dromozoa.parser.syntax_tree.to_grammar"

local class = clone(tree)

function class.new()
  local self = tree.new()
  class.create_node(self, "start").start = true
  return self
end

function class:start()
  if self:count_node("start") > 1 then
    error("only one start node allowed")
  end
  return apply(self:each_node("start"))
end

function class:builder()
  return builder(self)
end

function class:normalize()
  return normalize(self):apply()
end

function class:to_grammar()
  return to_grammar(self, grammar()):apply()
end

function class:write_graphviz(out)
  return tree.write_graphviz(self, out, graphviz_visitor())
end

local metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), metatable)
  end;
})
