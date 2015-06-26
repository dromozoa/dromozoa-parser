local clone = require "dromozoa.commons.clone"
local graph = require "dromozoa.graph"
local hash_map = require "dromozoa.parser.hash_map"
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
S -> E
E -> E + T
E -> T
T -> T * F
T -> F
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

local map = index_map()
for rule in _grammar:each() do
  local t = map:find(rule[1])
  if not t then
    t = {}
    map:insert(rule[1], t)
  end
  local u = clone(rule)
  table.remove(u, 1)
  t[#t + 1] = u
end

local nonterminal_symbols = index_set()
local symbols = index_map()

local g = graph()
local V = {}

print("--")
for head, bodies in map:each() do
  print(head)

  local x = index_set()
  symbols:insert(head, x)

  local v = g:create_vertex()
  v.label = head
  V[head] = v

  for i = 1, #bodies do
    local body = bodies[i]
    for j = 1, #body do
      local symbol = body[j]
      if not map:find(symbol) then
        if nonterminal_symbols:insert(symbol) == nil then
          local v = g:create_vertex()
          v.label = symbol
          V[symbol] = v
        end
      end
      x:insert(symbol)
    end
  end
end

print("--")
for symbol in nonterminal_symbols:each() do
  io.write(symbol, "\n")
end

print("--")
for k, v in symbols:each() do
  for x in v:each() do
    print(k, x)
    g:create_edge(V[k], V[x])
  end
end

local attributes = {}

function attributes:node_attributes(g, u)
  return { label = graphviz.quote_string(u.label) }
end
g:write_graphviz(assert(io.open("test.dot", "w")), graphviz_attributes_adapter(attributes)):close()

