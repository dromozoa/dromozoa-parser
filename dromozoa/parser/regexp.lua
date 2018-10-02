-- Copyright (C) 2017,2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local concat = require "dromozoa.parser.regexp.concat"
local difference = require "dromozoa.parser.regexp.difference"
local minimize = require "dromozoa.parser.regexp.minimize"
local nfa_to_dfa = require "dromozoa.parser.regexp.nfa_to_dfa"
local tree_to_nfa = require "dromozoa.parser.regexp.tree_to_nfa"
local union = require "dromozoa.parser.regexp.union"
local write_graph = require "dromozoa.parser.regexp.write_graph"

local class = {}
local metatable = { __index = class }

function class:nfa_to_dfa()
  return setmetatable(nfa_to_dfa(self), metatable)
end

function class:minimize()
  return setmetatable(minimize(self), metatable)
end

function class:concat(that)
  return concat(self, that)
end

function class:union(that)
  return union(self, that)
end

function class:difference(that)
  return setmetatable(difference(self, that), metatable)
end

function class:write_graph(out)
  if type(out) == "string" then
    write_graph(self, assert(io.open(out, "w"))):close()
  else
    return write_graph(self, out)
  end
end

return setmetatable(class, {
  __call = function (_, root, accept)
    return setmetatable(tree_to_nfa(root, accept), metatable)
  end;
})
