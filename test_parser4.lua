
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
  local bodies = rules[symbol]
  if bodies == nil then
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
    for head1, bodies in rules:each() do
      for body in bodies:each() do
        for i = 1, #body do
          local head2 = body[i]
          if rules[head2] ~= nil then
            local first = first_symbols(rules, sequence(body, i + 1))
            local removed = first:remove(EPSILON) ~= nil
            if set_union(followset[head2], first) > 0 then
              done = false
            end
            if removed then
              if set_union(followset[head2], followset[head1]) > 0 then
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

