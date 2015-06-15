local identity_generator = require "dromozoa.parser.identity_generator"

local function construct_grammar(_symbols, _grammar)
  if not _symbols then
    _symbols = identity_generator()
  end
  if not _grammar then
    _grammar = {}
  end

  local self = {}

  local function parse_rule(line)
    local head, body = line:match("^%s*(.-)%s*%->(.*)")
    if head then
      local dot
      local rule = {
        head = _symbols[head];
        body = {}
      }
      for v in body:gmatch("[^%s]+") do
        if v == "." then
          rule.dot = #rule.body + 1
        else
          table.insert(rule.body, _symbols[v])
        end
      end
      return rule
    end
  end

  function self:parse(text)
    for line in text:gmatch("[^\n]+") do
      if not line:match("^%s*#") then
        local rule = parse_rule(line)
        if rule then
          table.insert(_grammar, rule)
        end
      end
    end
    return self
  end

  local function unparse_rule(rule)
    local buffer = { _symbols[rule.head], "->" }
    for i, v in ipairs(rule.body) do
      if rule.dot == i then
        table.insert(buffer, ".")
      end
      table.insert(buffer, _symbols[v])
    end
    if rule.dot == #rule.body + 1 then
      table.insert(buffer, ".")
    end
    return table.concat(buffer, " ")
  end

  function self:unparse(out)
    for _, rule in ipairs(_grammar) do
      out:write(unparse_rule(rule), "\n")
    end
  end

  local function is_terminal_symbol(symbol)
    for _, rule in ipairs(_grammar) do
      if rule.head == symbol then
        return false
      end
    end
    return true
  end

  return self
end

local grammar = construct_grammar():parse([[
E -> E + T
E -> T
T -> T * F
T -> F
F -> ( E )
F -> id
]])

grammar:unparse(io.stdout)
