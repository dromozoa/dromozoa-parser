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

local function find(list, value)
  for i = 1, #list do
    if equal(list[i], value) then
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

local function map_insert(map, key, value)
  local list = map[key]
  if list then
    list[#list + 1] = value
  else
    map[key] = { value }
  end
end

-- set

local function set_insert(set, value)
  if not find(set, value) then
    set[#set + 1] = value
  end
end

local function set_index(set, id)
  local index_set = {}
  local index_map = {}
  for i = 1, #set do
    local value = set[i]
    set_insert(index_set, value[id])
    map_insert(index_map, value[id], value)
  end
  return index_set, index_map
end

local set = {}
set_insert(set, { "foo", "foo", "bar" })
set_insert(set, { "foo", "bar", "bar" })
set_insert(set, { "foo", "foo", "bar" })
set_insert(set, { "bar", "bar", "foo" })
local k, m = set_index(set, 3)
print(json.encode(k))
print(json.encode(m))



os.exit()



local function construct_grammar(_grammar)
  if not _grammar then
    _grammar = {}
  end

  local self = {}

  function self:parse(text)
    for line in text:gmatch("[^\n]+") do
      if not line:match("^%s*#") then
        local symbols = tokenize(line)
        local head = table.remove(symbols, 1)
        if table.remove(symbols, 1) == "->" then
          map_insert(_grammar, head, symbols)
        end
      end
    end
    return self
  end

  function self:unparse(out)
    for head, alternatives in pairs(_grammar) do
      for _, body in ipairs(alternatives) do
        out:write(head, " ->")
        for _, symbol in ipairs(body) do
          out:write(" ", symbol)
        end
        out:write("\n")
      end
    end
    return out
  end

  function self:is_terminal_symbol(symbol)
    return not _grammar[symbol]
  end

  function self:eliminate_left_recursion()
    local nonterminal_symbols = map_keyset(_grammar)
    print(json.encode(nonterminal_symbols))
    for i = 1, #nonterminal_symbols do
      local head = nonterminal_symbols[i]
      for j = 1, i - 1 do
        local symbol = nonterminal_symbols[j]
        local alternatives = {}
        for _, body in ipairs(_grammar[head]) do
          if body[1] == symbol then
            local body = clone(body)
            table.remove(body, 1)
            for _, body2 in ipairs(_grammar[symbol]) do
              table.insert(alternatives, list_join(body2, body))
            end
          else
            table.insert(alternatives, body)
          end
        end
        _grammar[head] = alternatives
      end
      local a1 = {}
      local a2 = {}
      local head2 = head .. "'"
      for _, body in ipairs(_grammar[head]) do
        if body[1] == head then
          local body = clone(body)
          table.remove(body, 1)
          table.insert(a2, list_join(body, { head2 }))
        else
          local body = clone(body)
          table.insert(a1, list_join(body, { head2 }))
        end
      end
      print(#a1, #a2)
      if #a2 > 0 then
        table.insert(a2, {})
        _grammar[head] = a1
        _grammar[head2] = a2
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

grammar:unparse(io.stdout)
io.write("--\n")
grammar:eliminate_left_recursion()
grammar:unparse(io.stdout)

-- for head, rules in pairs(grammar:rules()) do
--   print(head, #rules)
-- end

