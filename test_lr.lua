local clone = require "dromozoa.commons.clone"
local json = require "dromozoa.json"
local identity_generator = require "dromozoa.parser.identity_generator"

local symbols = identity_generator()

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

local function closure(grammar, itemset)
  local itemset = clone(itemset)
  -- io.write("<<<< closure <<<<\n", unparse_grammar(symbols, itemset))
  local added = {}
  local done
  repeat
    done = true
    for i = 1, #itemset do
      local item = itemset[i]
      assert(item.dot)
      local sym = item.body[item.dot]
      if sym then
        if not added[sym] then
          for _, rule in ipairs(grammar) do
            if rule.head == sym then
              local item = clone(rule)
              item.dot = 1
              table.insert(itemset, item)
              done = false
            end
          end
          added[sym] = true
        end
      end
    end
  until done
  -- io.write(">>>> closure >>>>\n", unparse_grammar(symbols, itemset))
  return itemset
end

local function items(grammar, start)
  local itemsets = { closure(grammar, start) }
  local done
  repeat
    done = true
    for i = 1, #itemsets do
      local itemset = itemsets[i]
      local syms = {}
      local added = {}
      for _, item in ipairs(itemset) do
        assert(item.dot)
        local sym = item.body[item.dot]
        if sym then
          if not added[sym] then
            table.insert(syms, sym)
            added[sym] = true
          end
        end
      end
      for _, sym in ipairs(syms) do
        local goto_itemset = {}
        for _, item in ipairs(itemset) do
          assert(item.dot)
          if sym == item.body[item.dot] then
            local item = clone(item)
            item.dot = item.dot + 1
            table.insert(goto_itemset, item)
          end
        end
        local goto_itemset = closure(grammar, goto_itemset)
        local found
        for _, itemset in ipairs(itemsets) do
          if equal(itemset, goto_itemset) then
            found = true
          end
        end
        if not found then
          table.insert(itemsets, goto_itemset)
          done = false
        end
      end
    end
  until done
  return itemsets
end

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

local itemsets = items(grammar, { parse_rule(symbols, "E' -> . E") })
for i, itemset in ipairs(itemsets) do
  io.write("==== ", i, " ====\n")
  io.write(unparse_grammar(symbols, itemset))
end
