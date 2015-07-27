
local linked_hash_table = require "dromozoa.commons.linked_hash_table"
local clone = require "dromozoa.commons.clone"
local unpack = require "dromozoa.commons.unpack"

local class = {}

function class:push(value, ...)
  if value == nil then
    return self
  else
    self[#self + 1] = value
    return class.push(self, ...)
  end
end

function class:copy(that, i, j)
  if i == nil then
    i = 1
  end
  if j == nil then
    j = #that
  end
  for i = i, j do
    self[#self + 1] = that[i]
  end
  return self
end

function class:each()
  return coroutine.wrap(function ()
    for i, v in ipairs(self) do
      coroutine.yield(v)
    end
  end)
end

local metatable = {
  __index = class;
}

local function sequence(that, i, j)
  local this = setmetatable({}, metatable)
  if that == nil then
    return this
  else
    return this:copy(that, i, j)
  end
  return setmetatable(this, metatable)
end

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
  local head, body, dot = item[1], item[2], item[3]
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
  out:write("\n")
end

local function each_nonterminal_symbol(rules)
  return coroutine.wrap(function ()
    for head in rules:each() do
      coroutine.yield(head)
    end
  end)
end

local function each_terminal_symbol(rules)
  return coroutine.wrap(function ()
    local visited = linked_hash_table()
    for _, bodies in rules:each() do
      for body in bodies:each() do
        for symbol in body:each() do
          if visited:insert(symbol) == nil then
            coroutine.yield(symbol)
          end
        end
      end
    end
  end)
end

local function each_symbol(rules)
  return coroutine.wrap(function ()
    for symbol in each_nonterminal_symbol(rules) do
      coroutine.yield(symbol)
    end
    for symbol in each_terminal_symbol(rules) do
      coroutine.yield(symbol)
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

local function first(rules, ...)
  return keys(first_symbol(rules, ...))
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

local function lr0_item(head, body, dot)
  return sequence():push(head):push(sequence(body)):push(dot)
end

local function lr0_closure(rules, I)
  local J = clone(I)
  local added = linked_hash_table()
  local done
  repeat
    done = true
    for item in J:each() do
      local head, body, dot = item[1], item[2], item[3]
      local symbol = body[dot]
      if symbol ~= nil then
        local bodies = rules[symbol]
        if bodies ~= nil then
          for body in bodies:each() do
            local item = lr0_item(symbol, body, 1)
            if added:insert(item) == nil then
              J:push(item)
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
  local g = sequence()
  for item in items:each() do
    local head, body, dot = item[1], item[2], item[3]
    if body[dot] == symbol then
      g:push(lr0_item(head, body, dot + 1))
    end
  end
  return lr0_closure(rules, g)
end

local function lr0_items(rules, start_items)
  local C = linked_hash_table()
  C:insert(lr0_closure(rules, start_items))
  local done
  repeat
    done = true
    for I in C:each() do
      for X in each_symbol(rules) do
        local g = lr0_goto(rules, I, X)
        if #g > 0 then
          if C:insert(g) == nil then
            done = false
          end
        end
      end
    end
  until done
  return C
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
  io.write("first(", symbol, ") = { ", table.concat(first(rules, symbol), ", "), " }\n")
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
  lr0_item("E", { "E" }, 2);
  lr0_item("E", { "E", "+", "T" }, 2);
}), "+")
io.write("--\n")
for item in g:each() do
  unparse_item(item, io.stdout)
end

local set_of_items = lr0_items(rules, sequence({ lr0_item("E'", { "E" }, 1) }))

io.write("==\n")
for items in set_of_items:each() do
  io.write("--\n")
  for item in items:each() do
    unparse_item(item, io.stdout)
  end
end

