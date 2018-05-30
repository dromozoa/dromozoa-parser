-- Copyright (C) 2018 Tomoyuki Fujimori <moyu@dromozoa.com>
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

local difference = require "dromozoa.parser.regexp.difference"
local merge = require "dromozoa.parser.regexp.merge"
local minimize = require "dromozoa.parser.regexp.minimize"
local nfa_to_dfa = require "dromozoa.parser.regexp.nfa_to_dfa"

local function visit(epsilons1, epsilons2, transitions, max_state, node, accept)
  local code = node[1]
  local a = node[2]
  local b = node[3]

  if code > 1 then
    max_state = visit(epsilons1, epsilons2, transitions, max_state, a, accept)
    if b then
      max_state = visit(epsilons1, epsilons2, transitions, max_state, b, accept)
    end
  end

  if code == 2 then -- concatenation
    node.u = a.u
    node.v = b.v
    epsilons1[a.v] = b.u
  else
    max_state = max_state + 1
    local u = max_state
    node.u = u
    max_state = max_state + 1
    local v = max_state
    node.v = v
    if code == 1 then -- character class
      for byte in pairs(a) do
        transitions[byte][u] = v
      end
    elseif code == 3 then -- union
      epsilons1[u] = a.u
      epsilons2[u] = b.u
      epsilons1[a.v] = v
      epsilons1[b.v] = v
    elseif code == 6 then -- difference
      local epsilons = { epsilons1, epsilons2 }

      local this = minimize(nfa_to_dfa({
        max_state = max_state;
        epsilons = epsilons;
        transitions = transitions;
        start_state = a.u;
        accept_states = { [a.v] = accept };
      }))
      local that = minimize(nfa_to_dfa({
        max_state = max_state;
        epsilons = epsilons;
        transitions = transitions;
        start_state = b.u;
        accept_states = { [b.v] = accept };
      }))
      local that = minimize(difference(this, that))

      local this, that = merge({
        max_state = max_state;
        epsilons = epsilons;
        transitions = transitions;
        start_state = u;
        accept_states = { [v] = accept };
      }, that)

      max_state = this.max_state
      epsilons1[u] = that.start_state
      for w in pairs(that.accept_states) do
        epsilons1[w] = v
      end
    else -- 0 or more repetition / optional
      local au = a.u
      local av = a.v
      epsilons1[u] = au
      epsilons2[u] = v
      epsilons1[av] = v
      if code == 4 then -- 0 or more repetition
        epsilons2[av] = au
      end
    end
  end

  return max_state
end

return function (root, accept)
  if not accept then
    accept = 1
  end

  local epsilons1 = {}
  local epsilons2 = {}
  local transitions = {}
  for byte = 0, 255 do
    transitions[byte] = {}
  end

  local max_state = visit(epsilons1, epsilons2, transitions, 0, root, accept)

  return {
    max_state = max_state;
    epsilons = { epsilons1, epsilons2 };
    transitions = transitions;
    start_state = root.u;
    accept_states = { [root.v] = accept };
  }
end
