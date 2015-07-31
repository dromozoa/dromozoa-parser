
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local equal = require "dromozoa.commons.equal"
local clone = require "dromozoa.commons.clone"
local sequence = require "dromozoa.parser.sequence"

local function keys(this)
  local keys = sequence()
  for key in this:each() do
    keys:push(key)
  end
  return keys
end

local function set_union(a, b)
  local n = 0
  for k, v in pairs(b) do
    if a[k] == nil then
      n = n + 1
      a[k] = v
    end
  end
  return n
end

local DOT = string.char(0xC2, 0xB7) -- MIDDLE DOT
local EPSILON = string.char(0xCE, 0xB5) -- GREEK SMALL LETTER EPSILON

local function parse_grammar(text)
  local rules = linked_hash_table()
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*#") then
      local head
      local body = sequence()
      for token in line:gmatch("%S+") do
        if head == nil then
          head = token
        elseif token ~= "->" then
          body:push(token)
        end
      end
      local bodies = rules[head]
      if bodies == nil then
        rules[head] = sequence({ body })
      else
        bodies:push(body)
      end
    end
  end
  return rules
end

local function unparse_grammar(rules, out)
  for head, bodies in rules:each() do
    out:write(head, " ->")
    local first = true
    for body in bodies:each() do
      if first then
        first = false
      else
        out:write(" |")
      end
      if #body == 0 then
        out:write(" ", EPSILON)
      else
        for symbol in body:each() do
          out:write(" ", symbol)
        end
      end
    end
    out:write("\n")
  end
end

local function unparse_item(item, out)
  local head, body, dot, term = item[1], item[2], item[3], item[4]
  out:write(head, " ->")
  for i = 1, #body do
    if dot == i then
      out:write(" ", DOT)
    end
    out:write(" ", body[i])
  end
  if dot == #body + 1 then
    out:write(" ", DOT)
  end
  if term ~= nil then
    out:write(", ", term)
  end
  out:write("\n")
end

local function make_item(head, body, dot, term)
  return sequence():push(head):push(sequence(body)):push(dot):push(term)
end

local function each_symbol(rules)
  return coroutine.wrap(function ()
    for head in rules:each() do
      coroutine.yield(head)
    end
    local terms = linked_hash_table()
    for _, bodies in rules:each() do
      for body in bodies:each() do
        for symbol in body:each() do
          if terms:insert(symbol) == nil then
            coroutine.yield(symbol)
          end
        end
      end
    end
  end)
end

local function is_terminal_symbol(rules, symbol)
  return rules[symbol] == nil
end

local function eliminate_immediate_left_recursion(rules, head1, bodies)
  local head2 = head1 .. "'"
  local bodies1 = sequence()
  local bodies2 = sequence()
  for body in bodies:each() do
    if body[1] == head1 then
      bodies2:push(sequence(body, 2):push(head2))
    else
      bodies1:push(sequence(body):push(head2))
    end
  end
  if #bodies2 > 0 then
    bodies2:push(sequence())
    rules[head1] = bodies1
    rules[head2] = bodies2
  end
end

local function eliminate_left_recursion(rules)
  local heads = keys(rules)
  for i = 1, #heads do
    local head1 = heads[i]
    local bodies1 = rules[head1]
    for j = 1, i - 1 do
      local head2 = heads[j]
      local bodies2 = rules[head2]
      local bodies = sequence()
      for body1 in bodies1:each() do
        if body1[1] == head2 then
          for body2 in bodies2:each() do
            bodies:push(sequence(body2):copy(body1, 2))
          end
        else
          bodies:push(body1)
        end
      end
      bodies1 = bodies
    end
    eliminate_immediate_left_recursion(rules, head1, bodies1)
  end
  return rules
end

local first_symbols

local function first_symbol(rules, symbol)
  local first = linked_hash_table()
  if is_terminal_symbol(rules, symbol) then
    first[symbol] = true
  else
    for body in rules[symbol]:each() do
      if #body == 0 then
        first:insert(EPSILON)
      else
        set_union(first, first_symbols(rules, body))
      end
    end
  end
  return first
end

function first_symbols(rules, symbols)
  local first = linked_hash_table()
  for symbol in symbols:each() do
    set_union(first, first_symbol(rules, symbol))
    if first:remove(EPSILON) == nil then
      return first
    end
  end
  first:insert(EPSILON)
  return first
end

local function make_followset(rules, start)
  local followset = linked_hash_table()
  for head in rules:each() do
    followset[head] = linked_hash_table()
  end
  followset[start]:insert("$")
  local done
  repeat
    done = true
    for head, bodies in rules:each() do
      for body in bodies:each() do
        for i = 1, #body do
          local symbol = body[i]
          if not is_terminal_symbol(symbol) then
            local first = first_symbols(rules, sequence(body, i + 1))
            local removed = first:remove(EPSILON) ~= nil
            if set_union(followset[symbol], first) > 0 then
              done = false
            end
            if removed then
              if set_union(followset[symbol], followset[head]) > 0 then
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

local function lr0_closure(rules, items)
  local items = clone(items)
  local added = linked_hash_table()
  local done
  repeat
    done = true
    for item in items:each() do
      local head, body, dot = item[1], item[2], item[3]
      local symbol = body[dot]
      if symbol ~= nil then
        local bodies = rules[symbol]
        if bodies ~= nil then
          for body in bodies:each() do
            local item = make_item(symbol, body, 1)
            if added:insert(item) == nil then
              items:push(item)
              done = false
            end
          end
        end
      end
    end
  until done
  return items
end

local function lr0_goto(rules, items, symbol)
  local g = sequence()
  for item in items:each() do
    local head, body, dot = item[1], item[2], item[3]
    if body[dot] == symbol then
      g:push(make_item(head, body, dot + 1))
    end
  end
  return lr0_closure(rules, g)
end

local function lr1_closure(rules, items)
  local items = clone(items)
  local added = linked_hash_table()
  local done
  repeat
    done = true
    for item in items:each() do
      local head, body, dot, term = item[1], item[2], item[3], item[4]
      local symbol = body[dot]
      if symbol ~= nil then
        local bodies = rules[symbol]
        if bodies ~= nil then
          for body2 in bodies:each() do
            local first = first_symbols(rules, sequence(body, dot + 1):push(term))
            for term2 in first:each() do
              local item = make_item(symbol, body2, 1, term2)
              if added:insert(item) == nil then
                items:push(item)
                done = false
              end
            end
          end
        end
      end
    end
  until done
  return items
end

local function lr1_goto(rules, items, symbol)
  local g = sequence()
  for item in items:each() do
    local head, body, dot, term = item[1], item[2], item[3], item[4]
    if body[dot] == symbol then
      g:push(make_item(head, body, dot + 1, term))
    end
  end
  return lr1_closure(rules, g)
end

local function items(rules, start_item, fn_closure, fn_goto)
  local set_of_items = linked_hash_table()
  set_of_items:insert(fn_closure(rules, sequence():push(start_item)))
  local done
  repeat
    done = true
    for I in set_of_items:each() do
      for X in each_symbol(rules) do
        local g = fn_goto(rules, I, X)
        if #g > 0 then
          if set_of_items:insert(g) == nil then
            done = false
          end
        end
      end
    end
  until done
  return set_of_items
end

local function lr0_items(rules, start_item)
  return items(rules, start_item, lr0_closure, lr0_goto)
end

local function lr1_items(rules, start_item)
  return items(rules, start_item, lr1_closure, lr1_goto)
end

local function construct_canonical_lr_parsing_tables(rules, start_item)
  local rules_map = linked_hash_table()
  local n = 0
  for head, bodies in rules:each() do
    for body in bodies:each() do
      io.write(n, ": ", head, " -> ", table.concat(body, " "), "\n")
      rules_map:insert({ head, body }, n)
      n = n + 1
    end
  end
  local C = lr1_items(rules, start_item)
  local C_map = linked_hash_table()
  local n = 0
  for items in C:each() do
    C[items] = n
    C_map[n] = items
    n = n + 1
  end
  local ACTION = linked_hash_table()
  for items, i in C:each() do
    for item in items:each() do
      local head, body, dot, term = item[1], item[2], item[3], item[4]
      local a = body[dot]
      if a == nil then
        if head == start_item[1] then
          assert(equal(body, start_item[2]))
          assert(equal(dot, start_item[3] + 1))
          assert(equal(term, start_item[4]))
          if ACTION:insert({ i, "$" }, { "acc" }) == nil then
            io.write("[", i, ",", "$", "] = accept\n")
          end
        else
          if ACTION:insert({ i, term }, { "r", rules_map[{ head, body }] }) == nil then
            io.write("[", i, ",", term, "] = reduce ", rules_map[{ head, body }], "\n")
          end
        end
      elseif is_terminal_symbol(rules, a) then
        local g = lr1_goto(rules, items, a)
        local j = C[g]
        assert(j ~= nil)
        if ACTION:insert({ i, a }, { "s", j }) == nil then
          io.write("[", i, ",", a, "] = shift ", j, "\n")
        end
      end
    end
  end
  local GOTO = linked_hash_table()
  for items, i in C:each() do
    for head in rules:each() do
      local g = lr1_goto(rules, items, head)
      local j = C[g]
      if j ~= nil then
        if GOTO:insert({ i, head }, j ) == nil then
          io.write("GOTO[", i, ",", head, "] = ", j, "\n")
        end
      end
    end
  end
  return rules_map, n, ACTION, GOTO
end

local function lr0_kernels(rules, start_item)
  local set_of_items = lr0_items(rules, start_item)
  local set_of_kernel_items = linked_hash_table()
  for items in set_of_items:each() do
    local kernel_items = sequence()
    for item in items:each() do
      local dot = item[3]
      if equal(item, start_item) or dot > 1 then
        kernel_items:push(item)
      end
    end
    if #kernel_items > 0 then
      set_of_kernel_items:insert(kernel_items)
    end
  end
  return set_of_kernel_items
end

local function determine_lookaheads(rules, start_item, symbol)
  local set_of_kernel_items = lr0_kernels(rules, start_item)
  for kernel_items in set_of_kernel_items:each() do
    for kernel_item in kernel_items:each() do
      unparse_item(kernel_item, io.stdout)
      local head, body, dot = kernel_item[1], kernel_item[2], kernel_item[3]
      local items = lr1_closure(rules, sequence():push(make_item(head, body, dot, "#")))
      for item in items:each() do
        local head, body, dot, term = item[1], item[2], item[3], item[4]
        if term == "#" then
        else
          local goto_item = make_item(head, body, dot + 1)
          io.write("  ", term, " ")
          unparse_item(goto_item, io.stdout)

          -- conclude that lookahead a is generated spontaneously for item `B -> c X dot d` in GOTO(I, X)
        end
      end
    end
  end
end

local rules = parse_grammar([[
S -> A a
S -> b
A -> A c
A -> S d
A ->
]])
eliminate_left_recursion(rules)
io.write("--\n")
unparse_grammar(rules, io.stdout)

local rules = parse_grammar([[
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])
eliminate_left_recursion(rules)
io.write("--\n")
unparse_grammar(rules, io.stdout)

for symbol in sequence({ "F", "T", "E", "E'", "T'" }):each() do
  io.write("first(", symbol, ") = { ", table.concat(keys(first_symbol(rules, symbol)), ", "), " }\n")
end

local followset = make_followset(rules, "E")
for symbol, follow in followset:each() do
  io.write("follow(", symbol, ") = { ", table.concat(keys(follow), ", "), " }\n")
end

local rules = parse_grammar([[
E' -> E
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])
io.write("--\n")
unparse_grammar(rules, io.stdout)

io.write("--\n")
for symbol in each_symbol(rules) do
  print(symbol)
end

local g = lr0_goto(rules, sequence({
  make_item("E", { "E" }, 2);
  make_item("E", { "E", "+", "T" }, 2);
}), "+")
io.write("--\n")
for item in g:each() do
  unparse_item(item, io.stdout)
end

local set_of_items = lr0_items(rules, make_item("E'", { "E" }, 1))

io.write("==\n")
for items in set_of_items:each() do
  io.write("--\n")
  for item in items:each() do
    unparse_item(item, io.stdout)
  end
end

local rules = parse_grammar([[
S' -> S
S -> C C
C -> c C
C -> d
]])
io.write("--\n")
unparse_grammar(rules, io.stdout)

local set_of_items = lr1_items(rules, make_item("S'", { "S" }, 1, "$" ))

io.write("==\n")
for items in set_of_items:each() do
  io.write("--\n")
  for item in items:each() do
    unparse_item(item, io.stdout)
  end
end

io.write("==\n")
local parsing_tables = construct_canonical_lr_parsing_tables(rules, make_item("S'", { "S" }, 1, "$"))

os.exit()

local rules = parse_grammar([[
S' -> S
S -> L = R
S -> R
L -> * R
L -> id
R -> L
]])
io.write("--\n")
unparse_grammar(rules, io.stdout)

local set_of_kernel_items = lr0_kernels(rules, make_item("S'", { "S" }, 1))
io.write("==\n")
for items in set_of_kernel_items:each() do
  io.write("--\n")
  for item in items:each() do
    unparse_item(item, io.stdout)
  end
end

io.write("==\n")
determine_lookaheads(rules, make_item("S'", { "S" }, 1))
