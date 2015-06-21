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

local function join_impl(this, that, ...)
  if that then
    local n = #this
    for i = 1, #that do
      this[n + i] = that[i]
    end
    return join_impl(this, ...)
  else
    return this
  end
end

local function join(...)
  return join_impl({}, ...)
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

local function set_join_impl(this, that, ...)
  if that then
    for i = 1, #that do
      set_insert(this, that[i])
    end
    return set_join_impl(this, ...)
  else
    return this
  end
end

local function set_join(...)
  return set_join_impl({}, ...)
end

-- grammar

local DOT = string.char(0xC2, 0xB7) -- MIDDLE DOT
local EPSILON = string.char(0xCE, 0xB5) -- GREEK SMALL LETTER EPSILON

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
              local rule = join(rule_j, rule_i)
              rule[1] = symbol_i
              set_insert(_grammar, rule)
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
      end
    end
  end

  function self:first_symbol(symbol)
    local map, set = set_index(_grammar, 1)
    if map[symbol] then
      local firsts = {}
      for _, rule in ipairs(map[symbol]) do
        if #rule > 1 then
          local symbols = clone(rule)
          table.remove(symbols, 1)
          firsts = set_join(firsts, self:first_symbols(symbols))
        else
          set_insert(firsts, EPSILON)
        end
      end
      return firsts
    else
      return { symbol }
    end
  end

  function self:first_symbols(symbols)
    local firsts = {}
    for i, symbol in ipairs(symbols) do
      local first = self:first_symbol(symbol)
      local removed = set_remove(first, EPSILON)
      firsts = set_join(firsts, first)
      if removed then
        if i == #symbols then
          set_insert(firsts, EPSILON)
        end
      else
        break
      end
    end
    return firsts
  end

  function self:follow_symbol(start)
    local followsets = {}
    local done = false
    while not done do
      for _, rule in ipairs(_grammar) do
      end
    end
  end

  function self:lr0_closure(items)
    local map, set = set_index(_grammar, 1)
    local items = clone(items)
    local done
    repeat
      done = true
      for _, item in ipairs(items) do
        local dot = find(item, DOT)
        local symbol = item[dot + 1]
        if symbol and map[symbol] then
          for _, rule in ipairs(map[symbol]) do
            local item = clone(rule)
            table.insert(item, 2, DOT)
            if set_insert(items, item) then
              done = false
            end
          end
        end
      end
    until done
    return items
  end

  function self:lr0_goto(items, symbol)
    local goto_items = {}
    for _, item in ipairs(items) do
      local dot = find(item, DOT)
      if symbol == item[dot + 1] then
        local item = clone(item)
        item[dot], item[dot + 1] = item[dot + 1], item[dot]
        set_insert(goto_items, item)
      end
    end
    return self:lr0_closure(goto_items)
  end

  function self:lr0_items(start)
    local map, set = set_index(_grammar, 1)
    local itemsets = { self:lr0_closure(start) }
    local done
    repeat
      done = true
      for i = 1, #itemsets do
        local items = itemsets[i]
        local symbols = {}
        for _, item in ipairs(items) do
          local symbol = item[find(item, DOT) + 1]
          if symbol then
            set_insert(symbols, symbol)
          end
        end
        for _, symbol in ipairs(symbols) do
          local goto_items = self:lr0_goto(items, symbol)
          if set_insert(itemsets, goto_items) then
            done = false
          end
        end
      end
    until done
    return itemsets
  end

  return self
end

local grammar = construct_grammar():parse([[
# S -> E
# E -> E + T
# E -> T
# T -> T * F
# T -> F
# F -> ( E )
# F -> id

# S -> A a
# S -> b
# A -> A c
# A -> S d
# A ->

S -> A B
A -> a
A ->
B -> b
B ->

# S -> E
# E -> E * B
# E -> E + B
# E -> B
# B -> 0
# B -> 1
]])

io.write("--\n")
grammar:unparse(io.stdout)
grammar:eliminate_left_recursion()
io.write("--\n")
grammar:unparse(io.stdout)
io.write("--\n")
print(json.encode(grammar:first_symbol("S")))
print(json.encode(grammar:first_symbols({ "A", "B" })))
-- print(json.encode(grammar:first_symbol("F")))
-- print(json.encode(grammar:first_symbol("T")))
-- print(json.encode(grammar:first_symbol("E")))
-- print(json.encode(grammar:first_symbol("E'")))
-- print(json.encode(grammar:first_symbol("T'")))
io.write("--\n")
-- print(json.encode(grammar:lr0_closure({ { "S", DOT, "E" } })))
-- local itemsets = grammar:lr0_items({ { "S", DOT, "E" } })
-- local itemsets = grammar:lr0_items({ { "E'", DOT, "E" } })

-- for i, items in ipairs(itemsets) do
--   io.write("==== ", i, " ====\n")
--   construct_grammar(items):unparse(io.stdout)
-- end


-- grammar:unparse(io.stdout)

-- for head, rules in pairs(grammar:rules()) do
--   print(head, #rules)
-- end

