local clone = require "dromozoa.commons.clone"
local json = require "dromozoa.json"
local graph = require "dromozoa.graph"
local hash_map = require "dromozoa.parser.hash_map"
local hash_set = require "dromozoa.parser.hash_set"
local index_map = require "dromozoa.parser.hash_map"
local index_set = require "dromozoa.parser.index_set"
local graphviz = require "dromozoa.graph.graphviz"
local graphviz_attributes_adapter = require "dromozoa.graph.graphviz_attributes_adapter"

local function tokenize(text)
  local tokens = {}
  local i = 0
  for token in text:gmatch("[^%s]+") do
    i = i + 1
    tokens[i] = token
  end
  return tokens
end

local _grammar = index_set()
local DOT = string.char(0xC2, 0xB7) -- MIDDLE DOT
local EPSILON = string.char(0xCE, 0xB5) -- GREEK SMALL LETTER EPSILON

local function parse(text)
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*#") then
      local rule = tokenize(line)
      if table.remove(rule, 2) == "->" then
        _grammar:insert(rule)
      end
    end
  end
end

local function unparse(out)
  for rule in _grammar:each() do
    out:write(rule[1], " ->")
    for i = 2, #rule do
      out:write(" ", rule[i])
    end
    out:write("\n")
  end
  return out
end

parse([[
# S -> E
# E -> E + T
# E -> T
# T -> T * F
# T -> F
# F -> ( E )
# F -> id

E -> T E'
E' -> + T E'
E' ->
T -> F T'
T' -> * F T'
T' ->
F -> ( E )
F -> id

# S -> A a
# S -> b
# A -> A c
# A -> S d
# A ->

# S -> A B
# A -> a
# A ->
# B -> b
# B ->

# S -> E
# E -> E * B
# E -> E + B
# E -> B
# B -> 0
# B -> 1
]])

unparse(io.stdout)

-- 非終端シンボル
-- 空のbody

-- グラフの終端から処理していく

local nonterminal_symbols = index_map()

local G = graph()
local V = {}
local E = hash_set()

for rule in _grammar:each() do
  local body = clone(rule)
  local head = table.remove(body, 1)

  local bodies = nonterminal_symbols:find(head)
  if not bodies then
    bodies = index_set()
    nonterminal_symbols:insert(head, bodies)
    local v = G:create_vertex(head)
    v.label = head
    V[head] = v
  end
  bodies:insert(body)
end

local terminal_symbols = index_set()

for head, bodies in nonterminal_symbols:each() do
  for body in bodies:each() do
    for i = 1, #body do
      local symbol = body[i]
      if not nonterminal_symbols:find(symbol) then
        if terminal_symbols:insert(symbol) == nil then
          local v = G:create_vertex(symbol)
          v.label = symbol
          V[symbol] = v
        end
      end
    end
  end
end

for head, bodies in nonterminal_symbols:each() do
  for body in bodies:each() do
    print(head, json.encode(body))
  end
end

for head, bodies in nonterminal_symbols:each() do
  for body in bodies:each() do
    for i = 1, #body do
      local symbol = body[i]
      if E:insert({ head, symbol }) == nil then
        G:create_edge(V[head], V[symbol])
      end
    end
  end
end

local firstset = {}

local function first(symbol)
  local firsts = firstset[symbol]
  if firsts then
    return firsts
  end

  firsts = index_set()
  firstset[symbol] = firsts

  if terminal_symbols:find(symbol) then
    firsts:insert(symbol)
  else
    local head = symbol
    for body in nonterminal_symbols[head]:each() do
      local n = #body
      if n > 0 then
        for i = 1, n do
          local symbol = body[i]
          local f = first(symbol)

          firsts:insert()
        end
      else
        firsts:insert(EPSILON)
      end
    end
  end

  return firsts
end



local attributes = {}

function attributes:node_attributes(g, u)
  return { label = graphviz.quote_string(u.label) }
end
G:write_graphviz(assert(io.open("test.dot", "w")), graphviz_attributes_adapter(attributes)):close()
