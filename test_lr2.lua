local clone = require "dromozoa.commons.clone"
local json = require "dromozoa.json"
local identity_generator = require "dromozoa.parser.identity_generator"

local function parse_rule(symbols, line)
  local head, body = line:match("^%s*(.-)%s*%->(.*)")
  if head then
    local rule = { symbols[head] }
    for v in body:gmatch("[^%s]+") do
      rule[#rule + 1] = symbols[v]
    end
    return rule
  end
end

local function unparse_rule(symbols, rule)
  local line = symbols[rule[1]] .. " ->"
  for i = 2, #rule do
    line = line .. " " .. symbols[rule[i]]
  end
  return line
end

local function parse_item(symbols, line)
  local head, body = line:match("^%s*(.-)%s*%->(.*)")
  if head then
    local dot
    local rule = { symbols[head] }
    for v in body:gmatch("[^%s]+") do
      if v == "." then
        dot = #rule + 1
      else
        rule[#rule + 1] = symbols[v]
      end
    end
    return { dot, rule }
  end
end

local function unparse_item(symbols, item)
  local dot = item[1] + 1
  local rule = item[2]
  local line = symbols[rule[1]] .. " ->"
  for i = 2, #rule do
    if i == dot then
      line = line .. " ."
    end
    line = line .. " " .. symbols[rule[i]]
  end
  return line
end

local function parse_grammar(symbols, text)
  local grammar = {}
  for line in text:gmatch("[^\n]+") do
    if not line:match("^%s*#") then
      grammar[#grammar + 1] = parse_rule(symbols, line)
    end
  end
  return grammar
end

local function closure(symbols, grammar, items)
  local items = clone(items)
  for i = 1, #items do
    print(unparse_item(symbols, items[i]))
  end
end

local symbols = identity_generator()

local grammar = parse_grammar(symbols, [[
E' -> E
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
# E -> E * B
# E -> E + B
# E -> B
# B -> 0
# B -> 1
]])

for i = 1, #grammar do
  print(unparse_rule(symbols, grammar[i]))
end

closure(symbols, grammar, { parse_item(symbols, "E' -> E .") })



