local graph = require "dromozoa.graph"
local bfs_visitor = require "dromozoa.graph.bfs_visitor"
local dfs_visitor = require "dromozoa.graph.dfs_visitor"
local graphviz = require "dromozoa.graph.graphviz"
local graphviz_attributes_adapter = require "dromozoa.graph.graphviz_attributes_adapter"

local json = require "dromozoa.json"
local linked_hash_table = require "dromozoa.parser.linked_hash_table"
local multimap = require "dromozoa.parser.multimap"

local function tokenize(text)
  local tokens = {}
  local n = 0
  for token in text:gmatch("%S+") do
    n = n + 1
    tokens[n] = token
  end
  return tokens
end

local function parse_grammar(text)
  local grammar = linked_hash_table()
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*#") then
      local body = tokenize(line)
      local head = table.remove(body, 1)
      if table.remove(body, 1) == "->" then
        grammar:insert({ head, body }, true)
      end
    end
  end
  return grammar
end

local function unparse_grammar(grammar, out)
  for rule in grammar:each() do
    local head, body = rule[1], rule[2]
    out:write(head, " ->")
    for i = 1, #body do
      out:write(" ", body[i])
    end
    out:write("\n")
  end
end

local function grammar_to_graph(grammar)
  local g = graph()
  local vertices = linked_hash_table():adapt()
  for rule in grammar:each() do
    local head, body = rule[1], rule[2]
    local u = vertices[head]
    if u == nil then
      u = g:create_vertex()
      u.label = head
      vertices[head] = u
    end
    local v = vertices[body]
    if v == nil then
      v = g:create_vertex()
      v.label = head .. " -> " .. table.concat(body, " ")
      vertices[body] = v
    end
    g:create_edge(u, v)
    for i = 1, #body do
      local sym = body[i]
      local w = vertices[sym]
      if w == nil then
        w = g:create_vertex()
        w.label = sym
        vertices[sym] = w
      end
      g:create_edge(v, w)
    end
  end
  return g, vertices
end

local graph_attributes = {}
function graph_attributes:node_attributes(g, u)
  return { label = graphviz.quote_string(u.label) }
end

local grammar = parse_grammar([[
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

-- unparse_grammar(grammar, io.stdout)
local g, vertices = grammar_to_graph(grammar)
g:write_graphviz(assert(io.open("test.dot", "w")), graphviz_attributes_adapter(graph_attributes)):close()

vertices.S:bfs(bfs_visitor({
  tree_edge = function (ctx, g, e, u, v)
    io.write(string.format("%s / %s\n", u.label, v.label))
  end;
}))
