local clone = require "dromozoa.commons.clone"
local json = require "dromozoa.json"
local identity_generator = require "dromozoa.parser.identity_generator"

local function equal(a, b)
  local t = type(a)
  if t == type(b) then
    if t == "table" then
      for k, v in next, a do
        if not equal(v, b[k]) then
          return false
        end
      end
      for k, v in next, b do
        if not equal(v, a[k]) then
          return false
        end
      end
      return true
    else
      return a == b
    end
  else
    return false
  end
end

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

local function construct_closure(grammar, items)
  local items = clone(items)
  local added = {}
  local done
  repeat
    done = true
    for i = 1, #items do
      local item = items[i]
      local sym = item.body[item.dot]
      if sym and not added[sym] then
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

local function construct_items(grammar, start)
  local itemsets = { construct_closure(grammar, start) }
  local done
  repeat
    done = true
    for i = 1, #itemsets do
      local items = itemsets[i]
      local syms = {}
      local added = {}
      for _, item in ipairs(items) do
        local sym = item.body[item.dot]
        if sym and not added[sym] then
          table.insert(syms, sym)
          added[sym] = true
        end
      end
      for _, sym in ipairs(syms) do
        local goto_items = {}
        for _, item in ipairs(items) do
          if sym == item.body[item.dot] then
            local item = clone(item)
            item.dot = item.dot + 1
            table.insert(goto_items, item)
          end
        end
        local goto_items = construct_closure(grammar, goto_items)
        local found
        for _, items in ipairs(itemsets) do
          if equal(items, goto_items) then
            found = true
          end
        end
        if not found then
          table.insert(itemsets, goto_items)
          done = false
        end
      end
    end
  until done
  return itemsets
end

local symbols = identity_generator()

local grammar = parse_grammar(symbols, [[
E' -> E
# E -> E + T
# E -> T
# T -> T * F
# T -> F
# F -> ( E )
# F -> id
E -> E * B
E -> E + B
E -> B
B -> 0
B -> 1
]])

local itemsets = construct_items(grammar, { parse_rule(symbols, "E' -> . E") })
for i, items in ipairs(itemsets) do
  io.write("==== ", i, " ====\n")
  io.write(unparse_grammar(symbols, items))
end
