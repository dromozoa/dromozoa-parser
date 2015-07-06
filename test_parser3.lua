local graph = require "dromozoa.graph"
local bfs_visitor = require "dromozoa.graph.bfs_visitor"
local dfs_visitor = require "dromozoa.graph.dfs_visitor"
local graphviz = require "dromozoa.graph.graphviz"
local graphviz_attributes_adapter = require "dromozoa.graph.graphviz_attributes_adapter"

local json = require "dromozoa.json"
local linked_hash_table = require "dromozoa.parser.linked_hash_table"
local multimap = require "dromozoa.parser.multimap"

local DOT = string.char(0xC2, 0xB7) -- MIDDLE DOT
local EPSILON = string.char(0xCE, 0xB5) -- GREEK SMALL LETTER EPSILON

local function tokenize(text)
  local tokens = {}
  local n = 0
  for token in text:gmatch("%S+") do
    n = n + 1
    tokens[n] = token
  end
  return tokens
end

local function concat(a, b, c)
  local n = #a
  for i = 1, n do
    c[i] = a[i]
  end
  for i = 1, #b do
    c[i + n] = b[i]
  end
  return c
end

local function view(a, b, m, n)
  if not m then
    m = 1
  end
  if not n then
    n = #a
  elseif n < 0 then
    n = #a + n + 1
  end
  m = m - 1
  n = n - m
  for i = 1, n do
    b[i] = a[i + m]
  end
  return b
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

local function remove_left_recursions_impl(i_body, j_bodies, o_bodies)
  for i = 1, #j_bodies do
    o_bodies[#o_bodies + 1] = concat(j_bodies[i], view(i_body, {}, 2), {})
  end
  return o_bodies
end

local function remove_left_recursions(grammar)
  local rules = linked_hash_table():adapt()
  for rule in grammar:each() do
    local head, body = rule[1], rule[2]
    print(head, json.encode(body))
    multimap.insert(rules, head, body)
  end
  local heads = {}
  for head in pairs(rules) do
    heads[#heads + 1] = head;
  end
  print("--")
  for i = 1, #heads do
    local i_head = heads[i]
    for j = 1, i - 1 do
      local i_bodies = rules[i_head]
      local j_head = heads[j]
      local j_bodies = rules[j_head]
      local o_bodies = {}
      for k = 1, #i_bodies do
        local i_body = i_bodies[k]
        if i_body[1] == j_head then
          remove_left_recursions_impl(i_body, j_bodies, o_bodies)
        else
          o_bodies[#o_bodies + 1] = i_body
        end
      end
      rules[i_head] = o_bodies
    end
    local bodies = rules[i_head]
    local i_bodies = {}
    local j_head = i_head .. "'"
    local j_bodies = {}
    for j = 1, #bodies do
      local body = bodies[j]
      print(i_head, json.encode(body))
      if body[1] == i_head then
        j_bodies[#j_bodies + 1] = concat(view(body, {}, 2), { j_head }, {})
      else
        i_bodies[#i_bodies + 1] = concat(body, { j_head }, {})
      end
    end
    if #j_bodies > 0 then
      j_bodies[#j_bodies + 1] = {};
      rules[i_head] = i_bodies
      rules[j_head] = j_bodies
    end
  end
  print("--")
  for head, body in multimap.each(rules) do
    print(head, json.encode(body))
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

local grammar = parse_grammar([[
# S -> E
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

remove_left_recursions(grammar)
os.exit()

-- unparse_grammar(grammar, io.stdout)
local g, vertices = grammar_to_graph(grammar)
g:write_graphviz(assert(io.open("test.dot", "w")), graphviz_attributes_adapter({
  node_attributes = function (ctx, g, u)
    return { label = graphviz.quote_string(u.label) }
  end;
})):close()

vertices.S:bfs(bfs_visitor({
  tree_edge = function (ctx, g, e, u, v)
    io.write(string.format("%s / %s\n", u.label, v.label))
  end;
}))
