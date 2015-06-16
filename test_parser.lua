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

local function find(set, value)
  for i = 1, #set do
    if equal(set[i], value) then
      return i
    end
  end
end

local function set_insert(set, value)
  if not find(set, value) then
    set[#set + 1] = value
  end
end

local function set_merge(a, b)
  local set = {}
  for i = 1, #a do
    set_insert(set, a[i])
  end
  for i = 1, #b do
    set_insert(set, b[i])
  end
  return set
end

local function map_keyset(map)
  local set = {}
  for k in pairs(map) do
    set[#set + 1] = k
  end
  return set
end

local function map_insert(map, key, value)
  local set = map[key]
  if set then
    set_insert(set, value)
  else
    map[key] = { value }
  end
end

local function tokenize(text)
  local tokens = {}
  for token in text:gmatch("[^%s]+") do
    tokens[#tokens + 1] = token
  end
  return tokens
end

local function construct_grammar(_grammar)
  if not _grammar then
    _grammar = {}
  end

  local self = {}

  function self:parse(text)
    for line in text:gmatch("[^\n]+") do
      if not line:match("^%s*#") then
        local tokens = tokenize(line)
        local head = table.remove(tokens, 1)
        if table.remove(tokens, 1) == "->" then
          map_insert(_grammar, head, tokens)
        end
      end
    end
    return self
  end

  function self:unparse(out)
    for head, bodies in pairs(_grammar) do
      for _, body in ipairs(bodies) do
        out:write(head, " ->")
        for _, v in ipairs(body) do
          out:write(" ", v)
        end
        out:write("\n")
      end
    end
    return out
  end

  function self:is_terminal_symbol(symbol)
    return not _grammar[symbol]
  end

  function eliminate_left_recursion()
    local nonterminal_symbols = map_keyset(_grammar)
    for i = 1, #nonterminal_symbols do
      local symbol_i = nonterminal_symbols[i]
      local bodies_i = _grammar[symbol_i]
      for j = 1, i - 1 do
        local symbol_j = nonterminal_symbols[j]
        local bodies_j = _grammar[symbol_j]
      end
    end
  end

  return self
end

local grammar = construct_grammar():parse([[
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])

grammar:unparse(io.stdout)

print(grammar:is_terminal_symbol("id"))
print(grammar:is_terminal_symbol("E"))

-- for head, rules in pairs(grammar:rules()) do
--   print(head, #rules)
-- end

