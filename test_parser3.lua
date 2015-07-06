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

local function remove_left_recursions(grammar)
  local rules = linked_hash_table():adapt()
  for rule in grammar:each() do
    local head, body = rule[1], rule[2]
    multimap.insert(rules, head, body)
  end
  local heads = {}
  for head in pairs(rules) do
    heads[#heads + 1] = head;
  end
  for i = 1, #heads do
    local head1 = heads[i]
    for j = 1, i - 1 do
      local head2 = heads[j]
      local bodies1 = rules[head1]
      local bodies2 = rules[head2]
      local bodies = {}
      for k = 1, #bodies1 do
        local body1 = bodies1[k]
        if body1[1] == head2 then
          for l = 1, #bodies2 do
            bodies[#bodies + 1] = concat(bodies2[l], view(body1, {}, 2), {})
          end
        else
          bodies[#bodies + 1] = body1
        end
      end
      rules[head1] = bodies
    end
    local head2 = head1 .. "'"
    local head2_as_body = { head2 }
    local bodies = rules[head1]
    local bodies1 = {}
    local bodies2 = {}
    for j = 1, #bodies do
      local body = bodies[j]
      if body[1] == head1 then
        bodies2[#bodies2 + 1] = concat(view(body, {}, 2), head2_as_body, {})
      else
        bodies1[#bodies1 + 1] = concat(body, head2_as_body, {})
      end
    end
    if #bodies2 > 0 then
      bodies2[#bodies2 + 1] = {};
      rules[head1] = bodies1
      rules[head2] = bodies2
    end
  end
  local result = linked_hash_table()
  for head, body in multimap.each(rules) do
    result:insert({ head, body }, true)
  end
  return result
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

local grammar2 = remove_left_recursions(grammar)
unparse_grammar(grammar2, io.stdout)
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
