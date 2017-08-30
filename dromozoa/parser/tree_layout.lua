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

-- http://dirk.jivas.de/papers/buchheim02improving.pdf

local function left_sibling(v)
  local number = v.number
  if number and number > 1 then
    return v.parent[number - 1]
  end
end

local function next_left(v)
  if #v > 0 then
    return v[1]
  else
    return v.thread
  end
end

local function next_right(v)
  local n = #v
  if n > 0 then
    return v[n]
  else
    return v.thread
  end
end

local function move_subtree(wl, wr, shift)
  local subtrees = wr.number - wl.number
  local shift_subtrees = shift / subtrees
  wr.change = wr.change - shift_subtrees
  wr.shift = wr.shift + shift
  wl.change = wl.change + shift_subtrees
  wr.prelim = wr.prelim + shift
  wr.mod = wr.mod + shift
end

local function execute_shifts(v)
  local shift = 0
  local change = 0
  for i = #v, 1, -1 do
    local w = v[i]
    w.prelim = w.prelim + shift
    w.mod = w.mod + shift
    change = change + w.change
    shift = shift + w.shift + change
  end
end

local function ancestor(vil, v, default_ancestor)
  local ancestor = vil.ancestor
  if ancestor.parent == v.parent then
    return ancestor
  else
    return default_ancestor
  end
end

local function apportion(v, default_ancestor, distance)
  local w = left_sibling(v)
  if w then
    local vir = v
    local vor = v
    local vil = w
    local vol = vir.parent[1] -- left most sibling
    local sir = vir.mod
    local sor = vor.mod
    local sil = vil.mod
    local sol = vol.mod
    local a
    local b
    while true do
      a = next_right(vil)
      b = next_left(vir)
      if not a or not b then
        break
      end
      vil = a
      vir = b
      vol = next_left(vol)
      vor = next_right(vor)
      vor.ancestor = v
      local shift = (vil.prelim + sil) - (vir.prelim + sir) + distance
      if shift > 0 then
        move_subtree(ancestor(vil, v, default_ancestor), v, shift)
        sir = sir + shift
        sor = sor + shift
      end
      sil = sil + vil.mod
      sir = sir + vir.mod
      sol = sol + vol.mod
      sor = sor + vor.mod
    end
    if a then
      if not next_right(vor) then
        vor.thread = a
        vor.mod = vor.mod + sil - sor
      end
    end
    if b then
      if not next_left(vol) then
        vol.thread = b
        vol.mod = vol.mod + sir - sol
        default_ancestor = v
      end
    end
  end
  return default_ancestor
end

local function first_walk(v, distance)
  local n = #v
  if n == 0 then
    local w = left_sibling(v)
    if w then
      v.prelim = w.prelim + distance
    else
      v.prelim = 0
    end
  else
    local default_ancestor = v[1]
    for i = 1, n do
      local w = v[i]
      first_walk(w, distance)
      default_ancestor = apportion(w, default_ancestor, distance)
    end
    execute_shifts(v)
    local midpoint = (v[1].prelim + v[n].prelim) * 0.5
    local w = left_sibling(v)
    if w then
      local prelim = w.prelim + distance
      v.prelim = prelim
      v.mod = prelim - midpoint
    else
      v.prelim = midpoint
    end
  end
end

local function second_walk(v, m, dy, kx, ky)
  local s = v.source
  s[kx] = v.prelim + m
  s[ky] = v.level * dy
  local m = m + v.mod
  for i = 1, #v do
    second_walk(v[i], m, dy, kx, ky)
  end
end

return function (root, dx, dy, kx, ky)
  if dx == nil then
    dx = 1
  end
  if dy == nil then
    dy = 1
  end
  if kx == nil then
    kx = "x"
  end
  if ky == nil then
    ky = "y"
  end

  local r = {
    source = root;
    level = 0;
    mod = 0;
  }
  r.ancestor = r
  local stack = { r }
  while true do
    local n = #stack
    local u = stack[n]
    if not u then
      break
    end
    stack[n] = nil
    local s = u.source
    local level = u.level + 1
    for i = #s, 1, -1 do
      local t = s[i]
      local v = {
        source = t;
        parent = u;
        number = i;
        level = level;
        mod = 0;
        change = 0;
        shift = 0;
      }
      v.ancestor = v
      u[i] = v
      stack[#stack + 1] = v
    end
  end
  first_walk(r, dx)
  second_walk(r, -r.prelim, dy, kx, ky)
end
