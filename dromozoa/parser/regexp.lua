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

local tag_names = {
  "[",
  "concat",
  "|",
  "*",
  "?",
}

local tag_table = {}
for i = 1, #tag_names do
  tag_table[tag_names[i]] = i
end

local max_terminal_tag = 1

local class = {
  tag_names = tag_names;
  tag_table = tag_table;
  max_terminal_tag = max_terminal_tag;
}

local function dfs_finish_edge(u, fn)
  local tag = u[1]
  if tag > max_terminal_tag then
    for i = 2, #u do
      local v = u[i]
      dfs_finish_edge(v, fn)
      fn(u, v)
    end
  end
end

function class.new(root)
  return {}
end

function class.tree_to_nfa(root)
  local n = 0
  local epsilons = {}
  local transitions = {}

  dfs_finish_edge(root, function (u, v)
    print(tag_names[u[1]], tag_names[v[1]])
  end)
end

class.metatable = {
  __index = class;
}

return setmetatable(class, {
  __call = function ()
    return setmetatable(class.new(), class.metatable)
  end;
})
