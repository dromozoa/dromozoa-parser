local clone = require "dromozoa.commons.clone"
local json = require "dromozoa.json"

local function equal(a, b)
  if a == b then
    return true
  else
    if type(a) == "table" and type(b) == "table" then
      for k, u in next, a do
        local v = b[k]
        if v == nil or not equal(u, v) then
          return false
        end
      end
      for k in next, b do
        if a[k] == nil then
          return false
        end
      end
      return getmetatable(a) == getmetatable(b)
    else
      return false
    end
  end
end

local function tokenize(text)
  local tokens = {}
  local i = 0
  for token in text:gmatch("[^%s]+") do
    i = i + 1
    tokens[i] = token
  end
  return tokens
end

-- list

local function find(this, value)
  for i = 1, #this do
    if equal(this[i], value) then
      return i
    end
  end
end

local function push(this, that)
  local n = #this
  for i = 1, #that do
    this[n + i] = that[i]
  end
  return this
end

local function join(this, that)
  return push(clone(this), that)
end

-- map

local function map_insert(this, key, value)
  local values = this[key]
  if values then
    values[#values + 1] = value
  else
    this[key] = { value }
  end
end

-- set

local function set_insert(this, value)
  if not find(this, value) then
    this[#this + 1] = value
    return true
  end
end

local function set_remove(this, value)
  local id = find(this, value)
  if id then
    table.remove(this, id)
    return true
  end
end

local function set_index(this, id)
  local map = {}
  local set = {}
  for i = 1, #this do
    local value = this[i]
    map_insert(map, value[id], value)
    set_insert(set, value[id])
  end
  return map, set
end

local function construct_grammar(_grammar)
  if not _grammar then
    _grammar = {}
  end

  local self = {}

  function self:parse(text)
    for line in text:gmatch("[^\n]+") do
      if not line:match("^%s*#") then
        local rule = tokenize(line)
        if table.remove(rule, 2) == "->" then
          set_insert(_grammar, rule)
        end
      end
    end
    return self
  end

  function self:unparse(out)
    for _, rule in ipairs(_grammar) do
      out:write(rule[1], " ->")
      for i = 2, #rule do
        out:write(" ", rule[i])
      end
      out:write("\n")
    end
    return out
  end

  function self:eliminate_left_recursion()
    local map, set = set_index(_grammar, 1)
    for i = 1, #set do
      local symbol_i = set[i]
      for j = 1, i - 1 do
        local symbol_j = set[j]
        for _, rule_i in ipairs(map[symbol_i]) do
          if rule_i[2] == symbol_j then
            set_remove(_grammar, rule_i)
            table.remove(rule_i, 1)
            table.remove(rule_i, 1)
            for _, rule_j in ipairs(map[symbol_j]) do
              local rule_j = clone(rule_j)
              rule_j[1] = symbol_i
              set_insert(_grammar, push(rule_j, rule_i))
            end
            map = set_index(_grammar, 1)
          end
        end
      end
      local a = {}
      local b = {}
      for _, rule in ipairs(map[symbol_i]) do
        if rule[2] == symbol_i then
          a[#a + 1] = rule
        else
          b[#b + 1] = rule
        end
      end
      if #a > 0 then
        local symbol_j = symbol_i .. "'"
        for _, rule in ipairs(b) do
          rule[#rule + 1] = symbol_j
        end
        for _, rule in ipairs(a) do
          rule[1] = symbol_j
          table.remove(rule, 2)
          rule[#rule + 1] = symbol_j
        end
        set_insert(_grammar, { symbol_j })
        map = set_index(_grammar, 1)
      end
    end
  end

  return self
end

local grammar = construct_grammar():parse([[
# E -> E + T
# E -> T
# T -> T * F
# T -> F
# F -> ( E )
# F -> id

S -> A a
S -> b
A -> A c
A -> S d
A ->
]])

io.write("--\n")
grammar:unparse(io.stdout)
grammar:eliminate_left_recursion()
io.write("--\n")
grammar:unparse(io.stdout)
-- grammar:unparse(io.stdout)

-- for head, rules in pairs(grammar:rules()) do
--   print(head, #rules)
-- end

