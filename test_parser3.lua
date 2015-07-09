local clone = require "dromozoa.commons.clone"
local graph = require "dromozoa.graph"
local bfs_visitor = require "dromozoa.graph.bfs_visitor"
local dfs_visitor = require "dromozoa.graph.dfs_visitor"
local graphviz = require "dromozoa.graph.graphviz"
local graphviz_attributes_adapter = require "dromozoa.graph.graphviz_attributes_adapter"

local json = require "dromozoa.json"
local linked_hash_table = require "dromozoa.parser.linked_hash_table"
local multimap = require "dromozoa.parser.multimap"
local set = require "dromozoa.parser.set"
local sequence = require "dromozoa.parser.sequence"

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
      local bodies = sequence.adapt({})
      for k = 1, #bodies1 do
        local body1 = bodies1[k]
        if body1[1] == head2 then
          for l = 1, #bodies2 do
            bodies:push_back(sequence.copy_adapt(bodies2[l]):concat(body1, 2))
          end
        else
          bodies:push_back(body1)
        end
      end
      rules[head1] = bodies
    end
    local head2 = head1 .. "'"
    local bodies = rules[head1]
    local bodies1 = sequence.adapt({})
    local bodies2 = sequence.adapt({})
    for j = 1, #bodies do
      local body = bodies[j]
      if body[1] == head1 then
        bodies2:push_back(sequence.copy_adapt(body, 2):push_back(head2))
      else
        bodies1:push_back(sequence.copy_adapt(body):push_back(head2))
      end
    end
    if #bodies2 > 0 then
      bodies2:push_back(sequence.adapt({}))
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
  local first = {}
  local bodies = rules[symbol]
  for i = 1, #bodies do
    local body = bodies[i]
    if #body > 0 then
      set.set_union(first, first_symbols(rules, body, firstset))
    else
      set.set_union(first, { [EPSILON] = true })
    end
  end
  firstset[symbol] = first
  return first
end

first_symbols = function (rules, symbols, firstset)
  local first = firstset[symbols]
  if first then
    return first
  end
  local first = {}
  for i = 1, #symbols do
    set.set_union(first, first_symbol(rules, symbols[i], firstset))
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
  terms["$"] = true
  for rule in grammar:each() do
    local body = rule[2]
    for i = 1, #body do
      local symbol = body[i]
      if rules[symbol] == nil then
        terms[symbol] = true
      end
    end
  end
  local firstset = linked_hash_table():adapt()
  for term in pairs(terms) do
    firstset[term] = { [term] = true }
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
  followset[start] = { ["$"] = true }
  local done
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
            follow_B = {}
            followset[B] = follow_B
          end
          local first_b = clone(first_symbols(rules, b, firstset))
          local epsilon_removed = set.remove(first_b, EPSILON)
          if set.set_union(follow_B, first_b) > 0 then
            done = false
          end
          if epsilon_removed then
            local follow_A = followset[head]
            if follow_A then
              if set.set_union(follow_B, follow_A) > 0 then
                done = false
              end
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

-- item = { head, body, dot }
-- body = { symbol... }
-- dot = N
local function lr0_closure(rules, I)
  local J = sequence.copy_adapt(I)
  local added = linked_hash_table()
  local done
  repeat
    done = true
    for i = 1, #J do
      local item = J[i]
      local head, body, dot = item[1], item[2], item[3]
      local B = body[dot]
      if B then
        local bodies2 = rules[B]
        if bodies2 then
          for j = 1, #bodies2 do
            local item2 = { B, bodies2[j], 1 }
            if added:insert(item2, true) == nil then
              J:push_back(item2)
              done = false
            end
          end
        end
      end
    end
  until done
  return J
end

local function lr0_goto(rules, items, symbol)
  local g = {}
  for i = 1, #items do
    local item = items[i]
    local head, body, dot = item[1], item[2], item[3]
    if body[dot] == symbol then
      g[#g + 1] = { head, body, dot + 1 }
    end
  end
  return lr0_closure(rules, g)
end

local function lr0_items(rules, start_items)
  local symbols = {}
  for head, body in multimap.each(rules) do
    set.insert(symbols, head)
    for i = 1, #body do
      set.insert(symbols, body[i])
    end
  end

  local set_of_items = linked_hash_table()
  set_of_items:insert(lr0_closure(rules, start_items), true)
  local done
  repeat
    done = true
    local C = set_of_items:clone()
    for items in set_of_items:each() do
      for symbol in pairs(symbols) do
        local g = lr0_goto(rules, items, symbol)
        if #g > 0 then
          if C:insert(g, true) == nil then
            done = false
          end
        end
      end
    end
    set_of_items = C
  until done

  return set_of_items
end

-- item = { head, body, dot, term }
local function lr1_closure(rules, I, nolr_rules, nolr_firstset)
  local J = sequence.copy_adapt(I)
  local done
  repeat
    for i = 1, #J do
      local item = J[i]
      local head, body, dot, term = item[1], item[2], item[3], item[4]
      local B = body[dot]
      if B then
        local bodies2 = rules[B]
        for j = 1, #bodies2 do
          local body2 = bodies2[j]
          local first = first_symbols(nolr_rules, sequence.copy_adapt(body, dot + 1):push_back(term), nolr_firstset)
          for term2 in pairs(first) do
            J:push_back({ B, body2, 1, term2 })
            done = false
          end
        end
      end
    end
    done = true
  until done
  return J
end

local function lr1_goto(rules, items, symbol, nolr_rules, nolr_firstset)
  local J = {}
  for i = 1, #items do
    local item = items[i]
    local head, body, dot, term = item[1], item[2], item[3], item[4]
    if body[dot] == symbol then
      J[#J + 1] = { head, body, dot + 1, term }
    end
  end
  return lr1_closure(rules, J, nolr_rules, nolr_firstset)
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
# E' -> E
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

print("--")
local C = lr0_closure(grammar_to_rules(grammar), { { "E'", { "E" }, 1 } })
for i = 1, #C do
  local c = C[i]
  print(c[1], json.encode(c[2]), c[3])
end

print("--")
local G = lr0_goto(grammar_to_rules(grammar), {
  { "E'", { "E" }, 2 },
  { "E", { "E", "+", "T" }, 2 },
}, "+")
for i = 1, #G do
  local g = G[i]
  print(g[1], json.encode(g[2]), g[3])
end

print("--")
local set_of_items = lr0_items(grammar_to_rules(grammar), {
  { "E'", { "E" }, 1 },
})

local n = 0
for items in set_of_items:each() do
  n = n + 1
  io.write("==== ", n, " =====\n")
  for i = 1, #items do
    local item = items[i]
    local head, body, dot = item[1], item[2], item[3]
    io.write(item[1], " ->")
    for j = 1, #body do
      if j == dot then
        io.write(" ", DOT)
      end
      io.write(" ", body[j])
    end
    if #body + 1 == dot then
      io.write(" ", DOT)
    end
    io.write("\n")
  end
end

print("--")
local C = lr1_goto(grammar_to_rules(grammar), {
  { "S'", { "S" }, 1, "$" },
  { "S", { "C", "C" }, 1, "$" },
  { "C", { "c", "C" }, 1, "c" },
  { "C", { "c", "C" }, 1, "d" },
  { "C", { "d" }, 1, "c" },
  { "C", { "d" }, 1, "d" },
}, "c", grammar_to_rules(grammar2), firstset)

for i = 1, #C do
  local c = C[i]
  print(c[1], json.encode(c[2]), c[3], c[4])
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
