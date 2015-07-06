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

local function set_size(a)
  local n = 0
  for k in pairs(a) do
    n = n + 1
  end
  return n
end

local function set_copy(a, b)
  for k, v in pairs(a) do
    b[k] = v
  end
  return b
end

local function includes(a, b)
  for k in pairs(b) do
    if a[k] == nil then
      return false
    end
  end
  return true
end

local function set_intersection(a, b, c)
  for k, v in pairs(a) do
    if b[k] ~= nil then
      c[k] = v
    end
  end
  return c
end

local function set_union(a, b, c)
  for k, v in pairs(a) do
    c[k] = v
  end
  local changed = false
  for k, v in pairs(b) do
    if a[k] == nil then
      c[k] = v
      changed = true
    end
  end
  return c, changed
end

local function set_difference(a, b, c)
  for k, v in pairs(a) do
    if b[k] == nil then
      c[k] = v
    end
  end
  return c
end

local function set_symmetric_difference(a, b, c)
  for k, v in pairs(a) do
    if b[k] == nil then
      c[k] = v
    end
  end
  for k, v in pairs(b) do
    if a[k] == nil then
      c[k] = v
    end
  end
  return c
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

local function grammar_to_rules(grammar)
  local rules = linked_hash_table():adapt()
  for rule in grammar:each() do
    local head, body = rule[1], rule[2]
    multimap.insert(rules, head, body)
  end
  return rules
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
  local rules = grammar_to_rules(grammar)
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

local first_symbols

local function first_symbol(rules, symbol, firstset)
  local first = firstset[symbol]
  if first then
    return first
  end
  first = linked_hash_table():adapt()
  local bodies = rules[symbol]
  for i = 1, #bodies do
    local body = bodies[i]
    local f
    if #body > 0 then
      f = first_symbols(rules, body, firstset)
    else
      f = linked_hash_table():adapt()
      f[EPSILON] = true
    end
    first = set_union(first, f, linked_hash_table():adapt())
  end
  firstset[symbol] = first
  return first
end

first_symbols = function (rules, symbols, firstset)
  local first = firstset[symbols]
  if first then
    return first
  end
  first = linked_hash_table():adapt()
  for i = 1, #symbols do
    local symbol = symbols[i]
    local f = first_symbol(rules, symbol, firstset)
    first = set_union(first, f, linked_hash_table():adapt())
    if first[EPSILON] then
      first[EPSILON] = nil
    else
      firstset[symbols] = first
      return first
    end
  end
  first[EPSILON] = true
  firstset[symbols] = first
  return first
end

local function make_firstset(grammar)
  local rules = grammar_to_rules(grammar)
  local terms = linked_hash_table():adapt()
  for rule in grammar:each() do
    local body = rule[2]
    for i = 1, #body do
      local sym = body[i]
      if rules[sym] == nil then
        terms[sym] = true
      end
    end
  end
  local firstset = linked_hash_table():adapt()
  for term in pairs(terms) do
    local first = linked_hash_table():adapt()
    first[term] = true
    firstset[term] = first
  end
  for head in pairs(rules) do
    first_symbol(rules, head, firstset)
  end
  return firstset
end

local function debug_set(prefix, set)
  io.write(prefix)
  for k, v in pairs(set) do
    io.write(" ", k)
  end
  io.write("\n")
end

local function make_followset(grammar, firstset, start)
  local rules = grammar_to_rules(grammar)
  local followset = linked_hash_table():adapt()
  local follow = linked_hash_table():adapt()
  follow["$"] = true
  followset[start] = follow
  local done
  local changed
  repeat
    done = true
    for rule in grammar:each() do
      local head, body = rule[1], rule[2]
      for i = 1, #body do
        local B = body[i]
        if rules[B] then
          local a = view(body, {}, 1, i - 1)
          local b = view(body, {}, i + 1)
          local follow_B = followset[B]
          if not follow_B then
            follow_B = linked_hash_table():adapt()
          end
          local first_b = first_symbols(rules, b, firstset)
          follow_B, changed = set_union(follow_B, set_difference(first_b, { [EPSILON] = true }, linked_hash_table():adapt()), linked_hash_table():adapt())
          if changed then done = false end
          followset[B] = follow_B
          if first_b[EPSILON] then
            local follow_A = followset[head]
            if follow_A then
              follow_B, changed = set_union(follow_B, follow_A, linked_hash_table():adapt())
              if changed then done = false end
              followset[B] = follow_B
            end
          end
        end
      end
    end
  until done
  return followset
end

local function follow_symbol(symbol, followset)
  return followset[symbol]
end

local function lr0_closure(grammar, rules, items)
  local t = linked_hash_table()
  local J = t:adapt()
  for k, v in pairs(items) do
    J[k] = v
  end
  local done
  repeat
    done = true
  until done
  return J
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

S' -> S
S -> C C
C -> c C
C -> d
]])

local grammar2 = remove_left_recursions(grammar)
unparse_grammar(grammar2, io.stdout)
local firstset = make_firstset(grammar2)

print("--")
for k, v in pairs(firstset) do
  io.write(json.encode(k), " :")
  for u in pairs(v) do
    io.write(" ", u)
  end
  io.write("\n")
end

local followset = make_followset(grammar2, firstset, "S'")

print("--")
for k, v in pairs(followset) do
  io.write(json.encode(k), " :")
  for u in pairs(v) do
    io.write(" ", u)
  end
  io.write("\n")
end

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
