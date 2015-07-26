
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
  local heads = sequence()
  for head in rules:each() do
    heads:push(head)
  end
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

local rules = parse_grammar([[
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
]])
eliminate_left_recursion(rules)
unparse_grammar(rules, io.stdout)

