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

local function is_terminal_symbol(grammar, sym)
  for _, rule in ipairs(grammar) do
    if rule.head == sym then
      return false
    end
  end
  return true
end

local function construct_rules(grammar, sym)
  local rules = {}
  for _, rule in ipairs(grammar) do
    if rule.head == sym then
      table.insert(rules, rule)
    end
  end
  return rules
end

local function remove_left_recursion(symbols, grammar)
  local nonterminal_symbols = {}
  for i = 1, #symbols do
    if not is_terminal_symbol(grammar, i) then
      table.insert(nonterminal_symbols, i)
    end
  end
  for i = 1, #nonterminal_symbols do
    local sym_i = nonterminal_symbols[i]
    for j = 1, i - 1 do
      local sym_j = nonterminal_symbols[j]
      local rules_j = construct_rules(grammar, sym_j)
      for k = #grammar, 1, -1 do
        local rule = grammar[k]
        if rule.head == sym_i and rule.body[1] == sym_j then
          table.remove(grammar, k)
          for _, rule_j in ipairs(rules_j) do
            local rule = clone(rule)
            table.remove(rule.body, 1)
            for i, v in ipairs(rule_j.body) do
              table.insert(rule.body, i, v)
            end
            table.insert(grammar, k, rule)
          end
        end
      end
    end
    local A = {}
    local B = {}
    for j = #grammar, 1, -1 do
      local rule = grammar[j]
      if rule.head == sym_i then
        if rule.body[1] == sym_i then
          table.insert(A, rule)
        else
          table.insert(B, rule)
        end
      end
    end
    if #A > 0 then
      for j = #grammar, 1, -1 do
        local rule = grammar[j]
        if rule.head == sym_i then
          table.remove(grammar, j)
        end
      end
      local dash = symbols[sym_i] .. "'"
      local sym = symbols[dash]
      for _, rule in ipairs(B) do
        table.insert(rule.body, sym)
        table.insert(grammar, rule)
      end
      for _, rule in ipairs(A) do
        rule.head = sym
        table.remove(rule.body, 1)
        table.insert(rule.body, sym)
        table.insert(grammar, rule)
      end
      table.insert(grammar, {
        head = sym;
        body = {};
      })
    end
  end
end

local function construct_first(grammar, sym)
  if is_terminal_symbol(grammar, sym) then
    return { sym }
  else
  end
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

local function construct_goto(grammar, items, sym)
  local goto_items = {}
  for _, item in ipairs(items) do
    if sym == item.body[item.dot] then
      local item = clone(item)
      item.dot = item.dot + 1
      table.insert(goto_items, item)
    end
  end
  return construct_closure(grammar, goto_items)
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
        local goto_items = construct_goto(grammar, items, sym)
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

local function construct_first_sets(symbols, grammar)
  local first_sets = {}

  for i = 1, #symbols do
    first_sets[i] = {}
  end

  local done
  repeat
    done = true
    for i = 1, #symbols do
      for _, rule in ipairs(grammar) do
        if grammar.head == i then
          local sym = grammar.body[1]
          if sym == nil then
            first_sets[i] = { 0 }
          elseif is_terminal_symbol(sym) then
            first_sets[i] = { sym }
          end
        end
      end

      if is_terminal_symbol(grammar, i) then
        

        print(i, symbols[i])
      else
      end
    end
  until done

  return first_sets
end

local symbols = identity_generator()

local grammar = parse_grammar(symbols, [[
S -> E
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id

# S -> E
# E -> E * B
# E -> E + B
# E -> B
# B -> 0
# B -> 1

# S -> A a
# S -> b
# A -> A c
# A -> S d
# A ->
]])

io.write(unparse_grammar(symbols, grammar))
io.write("--\n")

construct_first_sets(symbols, grammar)

-- remove_left_recursion(symbols, grammar)
-- print(json.encode(grammar))
-- io.write(unparse_grammar(symbols, grammar))
-- io.write(unparse_grammar(symbols, construct_rules(grammar, symbols.A)))

-- local itemsets = construct_items(grammar, { parse_rule(symbols, "E' -> . E") })
-- for i, items in ipairs(itemsets) do
--   io.write("==== ", i, " ====\n")
--   io.write(unparse_grammar(symbols, items))
-- end
