local clone = require "dromozoa.commons.clone"
local json = require "dromozoa.json"
local identity_generator = require "dromozoa.parser.identity_generator"

local function parse_rule(symbols, line)
  local head, body = line:match("^%s*(.-)%s*%->(.*)")
  if head then
    local dot
    local rule = {
      head = symbols[head];
      body = {};
    }
    for v in body:gmatch("[^%s]+") do
      if v == "." then
        rule.dot = #rule.body + 1
      else
        table.insert(rule.body, symbols[v])
      end
    end
    return rule
  end
end

local function unparse_rule(symbols, rule)
  local line = symbols[rule.head] .. " ->"
  for i, v in ipairs(rule.body) do
    if rule.dot == i then
      line = line .. " ."
    end
    line = line .. " " .. symbols[v]
  end
  if rule.dot == #rule.body + 1 then
    line = line .. " ."
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

local function unparse_grammar(symbols, grammar)
  local text = ""
  for _, v in ipairs(grammar) do
    text = text .. unparse_rule(symbols, v) .. "\n"
  end
  return text
end

local function closure(grammar, items)
  local items = clone(items)
  local added = {}
  for _, item in ipairs(items) do
    added[item.head] = true
  end
  local done
  repeat
    done = true
    for _, item in ipairs(items) do
      assert(item.dot)
      local sym = item.body[item.dot]
      if not added[sym] then
        for _, rule in ipairs(grammar) do
          if rule.head == sym then
            local item = clone(rule)
            item.dot = 1
            table.insert(items, item)
            done = false
          end
        end
        added[sym] = true
      end
    end
  until done
  return items
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

local clos = closure(grammar, { parse_rule(symbols, "E' -> . E") })
io.write(unparse_grammar(symbols, clos))

