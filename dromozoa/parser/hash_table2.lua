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

local hash_table_impl = require "dromozoa.parser.hash_table_impl"

local function HANDLE() end

local class = {}
local metatable = {}

function class.new()
  return {}
end

function class:adapt()
  return setmetatable(self, metatable)
end

function class:get(key)
  if key == nil then
    return nil
  end
  local t = type(key)
  if t == "number" or t == "string" or t == "boolean" then
    return rawget(self, key)
  end
  local impl = rawget(self, HANDLE)
  if impl == nil then
    return nil
  end
  return hash_table_impl.get(impl, key)
end

function class:empty()
  return next(self) == nil
end

function class:each()
  return coroutine.wrap(function ()
    for k, v in next, self do
      if k == HANDLE then
        for k, v in hash_table_impl.each(v) do
          coroutine.yield(k, v)
        end
      else
        coroutine.yield(k, v)
      end
    end
  end)
end

function class:set(key, value)
  if key == nil then
    error "table index is nil"
  end
  local t = type(key)
  if t == "number" or t == "string" or t == "boolean" then
    local v = rawget(self, key)
    rawset(self, key, value)
    return v
  end
  local impl = rawget(self, HANDLE)
  if impl == nil then
    impl = hash_table_impl.new()
    rawset(self, HANDLE, impl)
  end
  return hash_table_impl.set(impl, key, value)
end

function class:insert(key, value)
  if key == nil then
    error "table index is nil"
  end
  if value == nil then
    value = true
  end
  local t = type(key)
  if t == "number" or t == "string" or t == "boolean" then
    local v = rawget(self, key)
    if v == nil then
      rawset(self, key, value)
    end
    return v
  end
  local impl = rawget(self, HANDLE)
  if impl == nil then
    impl = hash_table_impl.new()
    rawset(self, HANDLE, impl)
  end
  return hash_table_impl.insert(impl, key, value)
end

function class:remove(key)
  if key == nil then
    error "table index is nil"
  end
  local t = type(key)
  if t == "number" or t == "string" or t == "boolean" then
    local v = rawget(self, key)
    rawset(self, key, nil)
    return v
  end
  local impl = rawget(self, HANDLE)
  if impl == nil then
    return nil
  end
  local v = hash_table_impl.remove(impl, key)
  if hash_table_impl.empty(impl) then
    rawset(self, HANDLE, nil)
  end
  return v
end

function metatable:__index(key)
  local fn = class[key]
  if fn == nil then
    return class.get(self, key)
  else
    return fn
  end
end

metatable.__newindex = class.set
metatable.__pairs = class.each

return setmetatable(class, {
  __call = function ()
    return class.adapt({})
  end;
})
