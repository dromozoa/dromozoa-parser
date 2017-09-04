-- Copyright (C) 2017 Tomoyuki Fujimori <moyu@dromozoa.com>
--
-- This file is part of dromozoa-parser.
--
-- dromozoa-parser is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- dromozoa-parser is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with dromozoa-parser.  If not, see <http://www.gnu.org/licenses/>.

local dumper = require "dromozoa.parser.dumper"
local escape_html = require "dromozoa.parser.escape_html"
local value = require "dromozoa.parser.symbol_value"
local lua53_lexer = require "dromozoa.parser.lexers.lua53_lexer"
local lua53_parser = require "dromozoa.parser.parsers.lua53_parser"
local write_html = require "dromozoa.parser.write_html"

local encode_string = dumper.encode_string
local keys = dumper.keys
local symbol_value = value

local function new_register(state)
  local register = state.register
  state.register = register + 1
  return register
end

local function new_label(state)
  local label = state.label
  state.label = label + 1
  return label
end

local function ref_constant(state, u, type, value)
  local constants = state.constants
  local n = #constants
  for i = n, 1, -1 do
    local constant = constants[i]
    if constant.type == type and constant.value == value then
      local refs = constant.refs
      refs[#refs + 1] = u
      return -i
    end
  end
  n = n + 1
  constants[n] = {
    type = type;
    value = value;
    refs = { u };
  }
  return -n
end

local function def_name(scope, u, type, value, r)
  local names = scope.names
  names[#names + 1] = {
    type = type;
    value = value;
    def = u.id;
    refs = {};
    r = r;
  }
  local locals = scope.state.locals
  locals[#locals + 1] = {
    value = value;
    r = r;
  }
end

local function ref_name(scope, u, value)
  local stack = { scope.state }
  while true do
    local state = scope.state
    local n = #stack
    if stack[n] ~= state then
      stack[n + 1] = state
    end

    local names = scope.names
    local n = #names
    for i = n, 1, -1 do
      local name = names[i]
      if name.value == value then
        local refs = name.refs
        refs[#refs + 1] = u.id
        local m = #stack - 1
        if m == 0 then
          return name.r, true
        else
          local state = stack[m]
          local r = name.r
          local upvalues = state.upvalues
          local u
          local l = #upvalues
          for j = 1, l do
            local upvalue = upvalues[j]
            if upvalue.r == r and upvalue.in_stack then
              u = j
              break
            end
          end
          if not u then
            u = l + 1
            upvalues[u] = {
              r = r;
              in_stack = true;
              name = name.value;
            }
          end
          r = u
          for j = m - 1, 1, -1 do
            local state = stack[j]
            local upvalues = state.upvalues
            local u
            local l = #upvalues
            for j = 1, l do
              local upvalue = upvalues[j]
              if upvalue.r == r and not upvalue.in_stack then
                u = j
                break
              end
            end
            if not u then
              u = l + 1
              upvalues[u] = {
                r = r;
                in_stack = false;
                name = name.value;
              }
            end
            r = u
          end
          return r, false
        end
      end
    end
    local parent = scope.parent
    if parent then
      scope = parent
    else
      names[#names + 1] = {
        value = value;
        refs = { u.id };
      }
      return
    end
  end
end

local function def_label(scope, u, value)
  local labels = scope.labels
  labels[#labels + 1] = {
    type = type;
    value = value;
    def = u.id;
    refs = {};
  }
end

local function copy_codes(result, source)
  for i = 1, #source do
    result[#result + 1] = source[i]
  end
  return result
end

local function add_state_html(state_html, state)
  if state then
    local constants = state.constants
    if constants[1] then
      local constant_tbody_html = { "tbody" }
      for i = 1, #constants do
        local constant = constants[i]
        local t = constant.type
        local v = constant.value
        if t == "string" then
          v = encode_string(v)
        end
        local refs = constant.refs
        local refs_html = { "td" }
        for j = 1, #refs do
          local ref = refs[j]
          local n = #refs_html
          if n == 1 then
            refs_html[n + 1] = { "span";
              ["data-ref"] = ref.id;
              "#" .. ref.id;
            }
          else
            refs_html[n + 1] = ","
            refs_html[n + 2] = { "span";
              ["data-ref"] = ref.id;
              "#" .. ref.id;
            }
          end
        end
        constant_tbody_html[#constant_tbody_html + 1] = { "tr";
          { "td"; i };
          { "td"; t };
          { "td"; v };
          refs_html;
        }
      end

      state_html[#state_html + 1] = { "div";
        { "span"; ["data-ref"] = state.id; "Constants" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "#" };
              { "th"; "Type" };
              { "th"; "Value" };
              { "th"; "Refs" };
            };
          };
          constant_tbody_html;
        };
      }
    end

    local locals = state.locals
    if locals[1] then
      local local_tbody_html = { "tbody" }
      for i = 1, #locals do
        local local_ = locals[i]
        local_tbody_html[#local_tbody_html + 1] = { "tr";
          { "td"; local_.r };
          { "td"; local_.value };
        }
      end

      state_html[#state_html + 1] = { "div";
        { "span"; ["data-ref"] = state.id; "Locals" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "#" };
              { "th"; "Name" };
            };
          };
          local_tbody_html;
        };
      }
    end

    local upvalues = state.upvalues
    if upvalues[1] then
      local upvalue_tbody_html = { "tbody" }
      for i = 1, #upvalues do
        local upvalue = upvalues[i]
        upvalue_tbody_html[#upvalue_tbody_html + 1] = { "tr";
          { "td"; i };
          { "td"; upvalue.name };
          { "td"; upvalue.r };
          { "td"; upvalue.in_stack };
        }
      end

      state_html[#state_html + 1] = { "div";
        { "span"; ["data-ref"] = state.id; "Upvalues" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "#" };
              { "th"; "Name" };
              { "th"; "ID" };
              { "th"; "in stack" };
            };
          };
          upvalue_tbody_html;
        };
      }
    end
  end
end

local function add_scope_html(scope_html, scope)
  if scope then
    local names = scope.names
    if names[1] then
      local name_tbody_html = { "tbody" }
      for i = 1, #names do
        local name = names[i]
        local def = name.def
        local def_html = { "td"; ["data-ref"] = def }
        if def then
          def_html[#def_html + 1] = "#" .. def
        end
        local refs = name.refs
        local refs_html = { "td" }
        for j = 1, #refs do
          local ref = refs[j]
          local n = #refs_html
          if n == 1 then
            refs_html[n + 1] = { "span";
              ["data-ref"] = ref;
              "#" .. ref;
            }
          else
            refs_html[n + 1] = ","
            refs_html[n + 2] = { "span";
              ["data-ref"] = ref;
              "#" .. ref;
            }
          end
        end
        name_tbody_html[#name_tbody_html + 1] = { "tr";
          { "td"; name.r };
          { "td"; name.type };
          { "td"; name.value };
          def_html;
          refs_html;
        }
      end

      scope_html[#scope_html + 1] = { "div";
        { "span"; ["data-ref"] = scope.id; "Names" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "#" };
              { "th"; "Type" };
              { "th"; "Name" };
              { "th"; "Def" };
              { "th"; "Refs" };
            };
          };
          name_tbody_html;
        };
      }
    end

    local labels = scope.labels
    if labels[1] then
      local label_tbody_html = { "tbody" }
      for i = 1, #labels do
        local label = labels[i]
        local def = label.def
        label_tbody_html[#label_tbody_html + 1] = { "tr";
          { "td"; label.value };
          { "td"; ["data-ref"] = def; "#" .. def };
          { "td" };
        }
      end

      scope_html[#scope_html + 1] = { "div";
        { "span"; ["data-ref"] = scope.id; "Labels" };
        { "table";
          { "thead";
            { "tr";
              { "th"; "Name" };
              { "th"; "Def" };
              { "th"; "Refs" };
            };
          };
          label_tbody_html;
        };
      }
    end
  end
end

local function add_code_html(code_html, u)
  local codes = u.codes
  if codes and codes[1] then
    local code_text_html = { "div" };
    for i = 1, #codes do
      local code = codes[i]
      local code_line_html = { "div"; code[1] }
      for j = 2, #code do
        local operand = code[j]
        if operand then
          code_line_html[#code_line_html + 1] = (" %.17g"):format(operand)
        else
          code_line_html[#code_line_html + 1] = " ?"
        end
      end
      code_text_html[#code_text_html + 1] = code_line_html
    end
    code_html[#code_html + 1] = { "div";
      ["data-id"] = "_" .. u.id;
      code_text_html;
    }
  end
end

local file, out_file = ...
local source

if file then
  local handle = assert(io.open(file))
  source = handle:read("*a")
  handle:close()
else
  source = io.read("*a")
end

local lexer = lua53_lexer()
local parser = lua53_parser()

local symbol_names = parser.symbol_names
local symbol_table = parser.symbol_table
local max_terminal_symbol = parser.max_terminal_symbol
local terminal_nodes = assert(lexer(source, file))
local root = assert(parser(terminal_nodes, source, file))

local id = 0
local state = {
  register = 0;
}
local env = {
  names = {};
  labels = {};
}
local scope = env
local loop
local protos = {}

local stack1 = { root }
local stack2 = {}
while true do
  local n1 = #stack1
  local n2 = #stack2
  local u = stack1[n1]
  if not u then
    break
  end
  if u == stack2[n2] then
    stack1[n1] = nil
    stack2[n2] = nil

    if u.state then
      state = state.parent
    end

    if u.scope then
      scope = scope.parent
    end

    if u.loop then
      loop = loop.parent
    end

    local v1, v2, v3, v4, v5 = u[1], u[2], u[3], u[4], u[5]
    local s = u[0]
    local s1 = v1 and v1[0]
    local s2 = v2 and v2[0]
    local s3 = v3 and v3[0]
    local s4 = v4 and v4[0]
    local s5 = v5 and v5[0]
    local codes = u.codes

    if s == symbol_table.chunk then
      local id = #protos + 1
      local proto_state = u.state
      protos[id] = {
        nparams = 0;
        constants = proto_state.constants;
        locals = proto_state.locals;
        upvalues = proto_state.upvalues;
        codes = v1.codes;
      }
      local r = new_register(state)
      u.r = r
      codes[#codes + 1] = { "CLOSURE", r, id }
    elseif s == symbol_table.block then
      if v1 then
        copy_codes(codes, v1.codes)
      end
      if v2 then
        copy_codes(codes, v2.codes)
      end
    elseif s == symbol_table.stats then
      for i = 1, #u do
        copy_codes(codes, u[i].codes)
      end
    elseif s == symbol_table.stat then
      if s1 == symbol_table.varlist then
        copy_codes(codes, v3.codes)
        for i = 1, #v1, 2 do
          local var = v1[i]
          local exp = v3[i]
          if var.in_stack then
            if exp then
              codes[#codes + 1] = { "MOVE", var.r, exp.r }
            else
              codes[#codes + 1] = { "LOADNIL", var.r }
            end
          else
            if exp then
              codes[#codes + 1] = { "SETUPVAL", var.r, exp.r }
            else
              local r = new_register(state)
              codes[#codes + 1] = { "LOADNIL", r }
              codes[#codes + 1] = { "SETUPVAL", var.r, r }
            end
          end
        end
      elseif s1 == symbol_table.functioncall then
        copy_codes(codes, v1.codes)
      elseif s1 == symbol_table["break"] then
        codes[#codes + 1] = { "JMP", loop.label }
      elseif s1 == symbol_table["while"] then
        local l = u.loop.label
        local m = new_label(state)
        codes[#codes + 1] = { "LABEL", m }
        copy_codes(codes, v2.codes)
        codes[#codes + 1] = { "TEST", v2.r, 0 }
        codes[#codes + 1] = { "JMP", l }
        copy_codes(codes, v4.codes)
        codes[#codes + 1] = { "JMP", m }
        codes[#codes + 1] = { "LABEL", l }
      elseif s1 == symbol_table.if_clauses then
        copy_codes(codes, v1.codes)
      elseif s1 == symbol_table["local"] then
        if s2 == symbol_table.namelist then
          if v4 then
            copy_codes(codes, v4.codes)
            for i = 1, #v2, 2 do
              local name = v2[i]
              local exp = v4[i]
              if exp then
                codes[#codes + 1] = { "MOVE", name.r, exp.r }
              else
                codes[#codes + 1] = { "LOADNIL", name.r }
              end
            end
          else
            for i = 1, #v2, 2 do
              local name = v2[i]
              codes[#codes + 1] = { "LOADNIL", name.r }
            end
          end
        end
      end
    elseif s == symbol_table.if_clauses or s == symbol_table.elseif_clauses then
      copy_codes(codes, v1.codes)
      if v2 then
        copy_codes(codes, v2.codes)
      end
      codes[#codes + 1] = { "LABEL", v1.l }
    elseif s == symbol_table.if_clause or s == symbol_table.elseif_clause then
      local l = new_label(state)
      local m = new_label(state)
      u.l = l
      copy_codes(codes, v2.codes)
      codes[#codes + 1] = { "TEST", v2.r, 0 }
      codes[#codes + 1] = { "JMP", m }
      copy_codes(codes, v4.codes)
      codes[#codes + 1] = { "JMP", l }
      codes[#codes + 1] = { "LABEL", m }
    elseif s == symbol_table.else_clause then
      copy_codes(codes, v2.codes)
    elseif s == symbol_table.retstat then
      if s2 == symbol_table.explist then
        copy_codes(codes, v2.codes)
        local a
        local n = #v2
        for i = 1, n, 2 do
          local exp = v2[i]
          local r = new_register(state)
          if not a then
            a = r
          end
          codes[#codes + 1] = { "MOVE", r, exp.r }
        end
        codes[#codes + 1] = { "RETURN", a, (n + 1) / 2 }
      else
        codes[#codes + 1] = { "RETURN", 0, 0 }
      end
    elseif s == symbol_table.label then
      def_label(scope, v2, symbol_value(v2))
    elseif s == symbol_table.var then
      if s1 == symbol_table.Name then
        local r, in_stack = ref_name(scope, v1, symbol_value(v1))
        if u.def then
          -- [TODO] impl set global
          -- [TODO] impl set upvalue
          u.r = r
          u.in_stack = in_stack
        else
          if r then
            if in_stack then
              local out = new_register(state)
              u.r = out
              codes[#codes + 1] = { "MOVE", out, r }
            else
              local out = new_register(state)
              u.r = out
              codes[#codes + 1] = { "GETUPVAL", out, r }
            end
          else
            local r1 = ref_constant(state, v1, "string", symbol_value(v1))
            local r2 = new_register(state)
            local r3 = new_register(state)
            u.r = r3
            codes[#codes + 1] = { "LOADK", r2, r1 }
            codes[#codes + 1] = { "GETGLOBAL", r3, r2 }
          end
        end
      elseif s1 == symbol_table.prefixexp then
        copy_codes(codes, v1.codes)
        local r
        if s3 == symbol_table.exp then
          r = v3.r
          copy_codes(codes, v3.codes)
        else
          local k = ref_constant(state, v3, "string", symbol_value(v3))
          r = new_register(state)
          codes[#codes + 1] = { "LOADK", r, k }
        end
        if u.def then
          -- [TODO] impl set table
        else
          local out = new_register(state)
          u.r = out
          codes[#codes + 1] = { "GETTABLE", out, v1.r, r }
        end
      end
    elseif s == symbol_table.namelist then
      for i = 1, #u, 2 do
        local name = u[i]
        local r = new_register(state)
        local value = symbol_value(name)
        name.r = r
        def_name(scope, name, "var", symbol_value(name), r)
      end
    elseif s == symbol_table.explist then
      for i = 1, #u, 2 do
        copy_codes(codes, u[i].codes)
      end
    elseif s == symbol_table.exp then
      if s1 == symbol_table["nil"] then
        local r = new_register(state)
        u.r = r
        codes[#codes + 1] = { "LOADNIL", r }
      elseif s1 == symbol_table["false"] then
        local r = new_register(state)
        u.r = r
        codes[#codes + 1] = { "LOADBOOL", r, 0 }
      elseif s1 == symbol_table["true"] then
        local r = new_register(state)
        u.r = r
        codes[#codes + 1] = { "LOADBOOL", r, 1 }
      elseif u.loadk then
        local r = new_register(state)
        u.r = r
        codes[#codes + 1] = { "LOADK", r, v1.r }
      elseif s1 == symbol_table.functiondef then
        u.r = v1.r
        u.codes = v1.codes
      elseif s1 == symbol_table.prefixexp then
        u.r = v1.r
        u.codes = v1.codes
      elseif s1 == symbol_table.functioncall then
        u.r = v1.r
        u.codes = v1.codes
      elseif s1 == symbol_table.tableconstructor then
        u.r = v1.r
        u.codes = v1.codes
      elseif s2 == symbol_table["+"] then
        local r = new_register(state)
        u.r = r
        copy_codes(codes, v1.codes)
        copy_codes(codes, v3.codes)
        codes[#codes + 1] = { "ADD", r, v1.r, v3.r }
      elseif s2 == symbol_table["*"] then
        local r = new_register(state)
        u.r = r
        copy_codes(codes, v1.codes)
        copy_codes(codes, v3.codes)
        codes[#codes + 1] = { "MUL", r, v1.r, v3.r }
      elseif s2 == symbol_table["=="] then
        local r = new_register(state)
        local l = new_label(state)
        local m = new_label(state)
        u.r = r
        copy_codes(codes, v1.codes)
        copy_codes(codes, v3.codes)
        codes[#codes + 1] = { "EQ", 0, v1.r, v3.r }
        codes[#codes + 1] = { "JMP", m }
        codes[#codes + 1] = { "LOADBOOL", r, 1 }
        codes[#codes + 1] = { "JMP", l }
        codes[#codes + 1] = { "LABEL", m }
        codes[#codes + 1] = { "LOADBOOL", r, 0 }
        codes[#codes + 1] = { "LABEL", l }
      elseif s2 == symbol_table["<="] then
        local r = new_register(state)
        local l = new_label(state)
        local m = new_label(state)
        u.r = r
        copy_codes(codes, v1.codes)
        copy_codes(codes, v3.codes)
        codes[#codes + 1] = { "LE", 0, v1.r, v3.r }
        codes[#codes + 1] = { "JMP", m }
        codes[#codes + 1] = { "LOADBOOL", r, 1 }
        codes[#codes + 1] = { "JMP", l }
        codes[#codes + 1] = { "LABEL", m }
        codes[#codes + 1] = { "LOADBOOL", r, 0 }
        codes[#codes + 1] = { "LABEL", l }
      end
    elseif s == symbol_table.prefixexp then
      if s1 == symbol_table.var then
        u.r = v1.r
        u.codes = v1.codes
      else
        local r = new_register(state)
        u.r = r
        codes[#codes + 1]  = { "MOVE", r, v2.r }
      end
    elseif s == symbol_table.functioncall then
      if s2 == symbol_table.args then
        local r = v2.r
        u.r = r
        copy_codes(codes, v1.codes)
        codes[#codes + 1] = { "MOVE", r, v1.r }
        copy_codes(codes, v2.codes)
        codes[#codes + 1] = { "CALL", r, v2.n + 1 }
      end
    elseif s == symbol_table.args then
      u.r = new_register(state)
      if s1 == symbol_table["("] then
        if s2 == symbol_table.explist then
          copy_codes(codes, v2.codes)
          local n = #v2
          for i = 1, n, 2 do
            local exp = v2[i]
            local r = new_register(state)
            codes[#codes + 1] = { "MOVE", r, exp.r }
          end
          u.n = (n + 1) / 2
        else
          u.n = 0
        end
      end
    elseif s == symbol_table.functiondef then
      u.r = v2.r
      u.codes = v2.codes
    elseif s == symbol_table.funcbody then
      local id = #protos + 1
      local proto_state = u.state
      if s2 == symbol_table.parlist then
        protos[id] = {
          nparams = proto_state.nparams;
          constants = proto_state.constants;
          locals = proto_state.locals;
          upvalues = proto_state.upvalues;
          codes = v4.codes;
        }
      else
        protos[id] = {
          nparams = 0;
          constants = proto_state.constants;
          locals = proto_state.locals;
          upvalues = proto_state.upvalues;
          codes = v3.codes;
        }
      end
      local r = new_register(state)
      u.r = r
      codes[#codes + 1] = { "CLOSURE", r, id }
    elseif s == symbol_table.parlist then
      if s1 == symbol_table.namelist then
        state.nparams = (#v1 + 1) / 2
        if v3 then
          def_name(scope, v3, "...", symbol_value(v3))
        end
      else
        state.nparams = 0
        def_name(scope, v1, "...", symbol_value(v1))
      end
    elseif s == symbol_table.tableconstructor then
      if s2 == symbol_table.fieldlist then
        local r = v2.r
        u.r = r
        codes[#codes + 1] = { "NEWTABLE", r }
        for i = 1, #v2, 2 do
          copy_codes(codes, v2[i].codes)
        end
      else
        local r = new_register(state)
        u.r = r
        codes[#codes + 1] = { "NEWTABLE", r }
      end
    elseif s == symbol_table.field then
      local p = u.parent
      if s2 == symbol_table.exp then
        copy_codes(codes, v2.codes)
        copy_codes(codes, v5.codes)
        codes[#codes + 1] = { "SETTABLE", p.r, v2.r, v5.r }
      elseif s1 == symbol_table.Name then
        local k = ref_constant(state, v1, "string", symbol_value(v1))
        local r = new_register(state)
        codes[#codes + 1] = { "LOADK", r, k }
        copy_codes(codes, v3.codes)
        codes[#codes + 1] = { "SETTABLE", p.r, r, v3.r }
      else
        local n = p.n + 1
        p.n = n
        local k = ref_constant(state, v1, "integer", n)
        local r = new_register(state)
        codes[#codes + 1] = { "LOADK", r, k }
        copy_codes(codes, v1.codes)
        codes[#codes + 1] = { "SETTABLE", p.r, r, v1.r }
      end
    elseif s == symbol_table.local_name then
      local r = new_register(state)
      u.r = r
      def_name(scope, v1, "var", symbol_value(v1), r)
    elseif s == symbol_table.LiteralString then
      u.r = ref_constant(state, u, "string", symbol_value(u));
    elseif s == symbol_table.IntegerConstant then
      u.r = ref_constant(state, u, "integer", tonumber(symbol_value(u)))
    elseif s == symbol_table.FloatConstant then
      u.r = ref_constant(state, u, "float", tonumber(symbol_value(u)))
    end
  else
    id = id + 1
    u.id = id

    if u.state then
      state = {
        id = id;
        parent = state;
        register = 0;
        label = 0;
        constants = {};
        locals = {};
        upvalues = {};
      }
      u.state = state
    end

    if u.scope then
      scope = {
        id = id;
        parent = scope;
        state = state;
        names = {};
        labels = {};
      }
      u.scope = scope
    end

    if u.loop then
      loop = {
        id = id;
        parent = loop;
        label = new_label(state)
      }
      u.loop = loop
    end

    if u[0] > max_terminal_symbol then
      u.codes = {}
    end

    if u[0] == symbol_table.fieldlist then
      u.r = new_register(state)
      u.n = 0
    end

    local order = u.order
    if order then
      local n = #order
      for i = 1, n do
        u[order[i]].parent = u
      end
      for i = #order, 1, -1 do
        stack1[#stack1 + 1] = u[order[i]]
      end
    else
      local n = #u
      for i = 1, n do
        u[i].parent = u
      end
      for i = n, 1, -1 do
        stack1[#stack1 + 1] = u[i]
      end
    end
    stack2[n2 + 1] = u
  end
end

local state_html = { "div"; class = "panel-pane state" }
local scope_html = { "div"; class = "panel-pane scope" }
local code_html = { "div"; class = "panel-pane code" }

add_scope_html(scope_html, env)

local stack1 = { root }
local stack2 = {}
while true do
  local n1 = #stack1
  local n2 = #stack2
  local u = stack1[n1]
  if not u then
    break
  end
  if u == stack2[n2] then
    stack1[n1] = nil
    stack2[n2] = nil
    local parent = u.parent
    if parent then
      local parent_html = parent.html
      local symbol = u[0]
      if symbol > max_terminal_symbol then
        parent_html[#parent_html + 1] = u.html
      else
        local p = u.p
        local i = u.i
        local j = u.j
        if p < i then
          parent_html[#parent_html + 1] = { "span";
            class = "color-skip";
            source:sub(p, i - 1);
          }
        end
        parent_html[#parent_html + 1] = { "span";
          id = "_" .. u.id;
          ["data-symbol"] = symbol;
          ["data-symbol-name"] = symbol_names[symbol];
          ["data-terminal-symbol"] = true;
          ["data-r"] = u.r;
          class = u.color;
          source:sub(i, j);
        }
      end
    end
  else
    local symbol = u[0]
    if symbol > max_terminal_symbol then
      add_state_html(state_html, u.state)
      add_scope_html(scope_html, u.scope)
      add_code_html(code_html, u)
      local order = u.order
      if order then
        order = table.concat(order, ",")
      end
      u.html = { "span",
        id = "_" .. u.id;
        ["data-symbol"] = symbol;
        ["data-symbol-name"] = symbol_names[symbol];
        ["data-order"] = order;
      }
    end
    local n = #u
    for i = n, 1, -1 do
      local v = u[i]
      stack1[#stack1 + 1] = v
    end
    stack2[n2 + 1] = u
  end
end

local root_html = root.html
local node = terminal_nodes[#terminal_nodes]
local p = node.p
local i = node.i
if p < i then
  root_html[#root_html + 1] = { "span";
    class = "color-skip";
    source:sub(p, i - 1);
  }
end

local line_number
if source:find("\n$") then
  line_number = 0
else
  line_number = 1
end
for _ in source:gmatch("\n") do
  line_number = line_number + 1
end

local number_width_rem = math.ceil(math.log(line_number, 10)) * 0.5
local number_html = { "div"; class="number" }
for i = 1, line_number do
  number_html[#number_html + 1] = { "span";
    class = "color-number";
    i;
    "\n";
  }
end

local panel_width_rem = 40
local panel_html = { "div"; class="panel";
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "Tree" };
  };
  { "div"; class = "panel-pane tree" };
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "State" };
  };
  state_html;
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "Scope" };
  };
  scope_html;
  { "div"; class = "panel-head";
    { "span"; class = "icon fa fa-minus-square-o" };
    { "span"; "Code" };
  };
  code_html;
}

local transition_duration = 400

-- https://github.com/tbastos/vim-lua
-- https://github.com/reedes/vim-colors-pencil
local style = [[
@font-face {
  font-family: 'Noto Sans Mono CJK JP';
  font-style: normal;
  font-weight: 400;
  src: url('https://dromozoa.s3.amazonaws.com/mirror/NotoSansCJKjp-2017-04-03/NotoSansMonoCJKjp-Regular.otf') format('opentype');
}

@font-face {
  font-family: 'Noto Sans Mono CJK JP';
  font-style: normal;
  font-weight: 700;
  src: url('https://dromozoa.s3.amazonaws.com/mirror/NotoSansCJKjp-2017-04-03/NotoSansMonoCJKjp-Bold.otf') format('opentype');
}

body {
  margin: 0;
  font-family: 'Noto Sans Mono CJK JP', monospace;
  white-space: pre;
  font-weight: 400;

  background-color: #FFFFFF; /* actual_white */
  color: #424242; /* light_black */
}

.body {
  position: relative;
}

.number {
  position: absolute;
  top: 0;
  left: 0.5rem;
  text-align: right;
}

.source {
  position: absolute;
  top: 0;
  left: ]] .. number_width_rem + 1.5 .. [[rem;
}

.panel {
  position: fixed;
  top: 0;
  right: 0;
  width: ]] .. panel_width_rem .. [[rem;
  height: 100vh;
  overflow: scroll;
}

.panel-head {
  background-color: rgba(198, 198, 198, 0.5); /* lighter_gray */
}

.panel-pane {
  background-color: rgba(241, 241, 241, 0.5); /* white */
}

.icon {
  width: 1.5rem;
  text-align: center;
}

.tree {
  height: 20rem;
}

.code {
  min-height: 1.5rem;
}

.color-number {
  color: #C6C6C6; /* ligher_gray */
}

.color-skip {
  color: #B2B2B2; /* light_gray */
}

.color-constant {
  color: #20A5BA; /* dark_cyan */
}

.color-operator,
.color-statement {
  color: #10A778; /* dark_green */
}

.color-structure,
[data-symbol-name='funcbody'] > [data-symbol-name='end'] {
  color: #C30771; /* dark_red */
}

.source span {
  transition: background-color ]] .. transition_duration .. [[ms;
}

.source span.color-active {
  background-color: #F3E430; /* yellow */
  transition: background-color ]] .. transition_duration .. [[ms;
}

.viewport > rect {
  fill-opacity: 0;
}

.edge path {
  fill: none;
  stroke: #000000;
}

.node rect {
  fill: #FFFFFF; /* actual_white */
  stroke: #000000;
  transition: fill ]] .. transition_duration .. [[ms;
}

.node rect.color-active {
  fill: #F3E430; /* yellow */
  transition: fill ]] .. transition_duration .. [[ms;
}

.state table,
.scope table {
  border-collapse: collapse;
}

.state th,
.state td,
.scope th,
.scope td {
  border: solid 1px #000000;
}

.code [data-id] {
  display: none;
}
]]

local script = [[
(function (root) {
  var setTimeout = root.setTimeout;
  var $ = root.jQuery;
  var d3 = root.d3;

  var panel_width_rem = ]] .. panel_width_rem .. [[;
  var transition_duration = ]] .. transition_duration .. [[;

  var update_node_group = function (node_group) {
    var group = node_group.select("g");
    var rect = group.select("rect");
    var text = group.select("text");
    var bbox = text.node().getBBox();
    var x = bbox.x;
    var y = bbox.y;
    var w = bbox.width;
    var h = bbox.height;
    var r = h * 0.5;
    rect
      .attr("x", x - r)
      .attr("y", y)
      .attr("width", w + h)
      .attr("height", h)
      .attr("rx", r)
      .attr("rx", r);
    group
      .attr("transform", "translate(" + (- w * 0.5) + "," + (- y - r) + ")");
  };

  var update_node_groups = function (count) {
    d3.selectAll("g.node").each(function (d) {
      update_node_group(d3.select(this));
    });
    if (--count > 0) {
      setTimeout(function () {
        update_node_groups(count);
      }, 200);
    }
  };

  $(function () {
    var $tree = $(".tree");
    var tree_width = $tree.width();
    var tree_height = $tree.height();
    var rem = tree_width / panel_width_rem;

    var node_width = 10 * rem;
    var node_height = 2 * rem;

    var initial_zoom_x = node_width * 0.5;
    var initial_zoom_y = tree_height * 0.5;
    var initial_zoom_scale = 1;
    var initial_transform = d3.zoomIdentity
      .translate(initial_zoom_x, initial_zoom_y)
      .scale(initial_zoom_scale);

    var zoom = d3.zoom();
    var zoom_x = 0;
    var zoom_y = 0;
    var zoom_scale = 1;

    $("[data-terminal-symbol]").on("click", function () {
      var node_group = $(this).data("node_group");
      var d = node_group.datum();
      var zx = tree_width * 0.5 - d.data.tx * zoom_scale;
      var zy = tree_height * 0.5 - d.data.ty * zoom_scale;
      var transform = d3.zoomIdentity
        .translate(zx, zy)
        .scale(zoom_scale);
      d3.selectAll(".color-active")
        .classed("color-active", false);
      $(this)
        .addClass("color-active");
      node_group.select("rect")
        .classed("color-active", true);
      d3.select("g.viewport")
        .transition().duration(transition_duration)
        .call(zoom.transform, transform);
    });

    $(".panel-head").on("click", function () {
      var $this = $(this);
      var $area = $this.next();
      var $icon = $this.children(".icon")
        .attr("class", "icon fa fa-spinner fa-spin");
      if ($area.is(":visible")) {
        $area.slideUp(transition_duration, function () {
          $icon.attr("class", "icon fa fa-plus-square-o");
        });
      } else {
        $area.slideDown(transition_duration, function () {
          $icon.attr("class", "icon fa fa-minus-square-o");
        });
      }
    });

    $("[data-ref]").on("click", function (ev) {
      ev.stopPropagation();
      var $this = $(this);
      var $node = $("#_" + $this.attr("data-ref"));
      var scroll = $node.offset().top - 1.5 * rem;
      if (scroll < 0) {
        scroll = 0;
      }
      d3.selectAll(".color-active")
        .classed("color-active", false);
      $node
        .addClass("color-active");
      $("body").animate({
        scrollTop: scroll
      }, transition_duration);
    });

    var svg = d3.select(".tree")
      .append("svg")
        .attr("width", tree_width)
        .attr("height", tree_height)
        .style("display", "block");

    var viewport_group = svg.append("g")
      .classed("viewport", true)
      .call(zoom.on("zoom", function () {
        var transform = d3.event.transform;
        zoom_x = transform.x;
        zoom_y = transform.y;
        zoom_scale = transform.k;
        d3.select("g.view").attr("transform", transform.toString());
      }));

    viewport_group.append("rect")
      .attr("width", tree_width)
      .attr("height", tree_height);

    var view_group = viewport_group.append("g")
      .classed("view", true);

    viewport_group.call(zoom.transform, initial_transform);

    var model_group = view_group.append("g")
      .classed("model", true);

    var tree_root = d3.hierarchy({ $node: $("[data-symbol-name=chunk]") }, function (node) {
      var $node = node.$node;
      var order = $node.attr("data-order");
      var children = [];
      $node.children("[data-symbol]").each(function () {
        children.push({ $node: $(this) })
      });
      if (order) {
        var ordered = [];
        $.each(order.split(","), function (i, v) {
          ordered[i] = children[v - 1];
        });
        return ordered;
      } else {
        return children;
      }
    });

    var tree = d3.tree();
    tree.nodeSize([ node_height, node_width ]);
    tree(tree_root);

    model_group.append("g")
      .classed("edges", true)
      .selectAll(".edge")
        .data(tree_root.descendants().slice(1))
        .enter().append("g")
          .classed("edge", true)
          .append("path")
            .attr("d", function (d) {
              var p = d.parent;
              var sx = p.y;
              var sy = p.x;
              var ex = d.y;
              var ey = d.x;
              var mx = (sx + ex) * 0.5;
              var path = d3.path();
              path.moveTo(sx, sy);
              path.bezierCurveTo(mx, sy, mx, ey, ex, ey)
              return path.toString();
            });

    model_group.append("g")
      .classed("nodes", true)
      .selectAll(".node")
        .data(tree_root.descendants())
        .enter().append("g")
          .classed("node", true)
          .each(function (d) {
            var node_group = d3.select(this);
            var $node = d.data.$node;
            $node.data("node_group", node_group);
            group = node_group.append("g");
            group.append("rect");
            group.append("text")
              .text($node.attr("data-symbol-name"));
            d.data.tx = d.y;
            d.data.ty = d.x;
            node_group
              .attr("transform", "translate(" + d.y + "," + d.x + ")")
              .on("click", function (d) {
                var scroll = $node.offset().top - 1.5 * rem;
                if (scroll < 0) {
                  scroll = 0;
                }
                d3.selectAll(".color-active")
                  .classed("color-active", false);
                $node
                  .addClass("color-active");
                d3.select(this).select("rect")
                  .classed("color-active", true);
                $("body").animate({
                  scrollTop: scroll
                }, transition_duration);
                $(".code [data-id]").hide(transition_duration);
                $(".code [data-id=" + $node.attr("id") + "]").show(transition_duration);
              });
            update_node_group(node_group);
          });

    update_node_groups(10);
  });
}(this));
]]

write_html(io.stdout, { "html";
  { "head";
    { "meta"; charset="utf-8"; };
    { "title"; "lua-to-html" };
    { "link"; rel = "stylesheet"; href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css" };
    { "style"; style };
  };
  { "body";
    { "div"; class="body";
      number_html;
      { "div"; class="source"; root_html };
      panel_html;
    };
    { "script"; src = "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.2.1/jquery.min.js" };
    { "script"; src = "https://cdnjs.cloudflare.com/ajax/libs/d3/4.10.0/d3.min.js" };
    { "script"; script };
  };
})
io.write("\n")

if out_file then
  local out = assert(io.open(out_file, "w"))

  out:write([[
local lua_state = require "test.lua_state"
local L = lua_state()
]])

  for i = 1, #protos do
    local proto = protos[i]
    out:write("local proto = { K = {}, U = {} }\n")
    local constants = proto.constants
    for j = 1, #constants do
      local constant = constants[j]
      if constant.type == "string" then
        out:write("proto.K[", j, "] = ", encode_string(constant.value), "\n")
      else
        out:write("proto.K[", j, "] = ", constant.value, "\n")
      end
    end
    local upvalues = proto.upvalues
    for j = 1, #upvalues do
      local upvalue = upvalues[j]
      out:write("proto.U[", j, "] = { ", upvalue.r, ", ", tostring(upvalue.in_stack), " }\n")
    end
    out:write("proto.codes = function (...)\n")
    out:write("L:args(", proto.nparams, ", ...)\n")
    local codes = proto.codes

    do
      local i = 1
      local n = #codes
      while i <= n do
        local code = codes[i]
        local op = code[1]
        if op == "JMP" then
          out:write("goto L", code[2], "\n")
        elseif op == "LABEL" then
          out:write("::L", code[2], "::\n")
        elseif op == "TEST" then
          i = i + 1
          local jump = codes[i]
          assert(jump[1] == "JMP")
          if code[3] == 0 then
            out:write("if not L:get(", code[2], ") then goto L", jump[2], " end\n")
          else
            out:write("if L:get(", code[2], ") then goto L", jump[2], " end\n")
          end
        elseif op == "EQ" then
          i = i + 1
          local jump = codes[i]
          assert(jump[1] == "JMP")
          if code[2] == 0 then
            out:write("if not (L:get(", code[3], ") == L:get(", code[4], ")) then goto L", jump[2], " end\n")
          else
            out:write("if L:get(", code[3], ") == L:get(", code[4], ") then goto L", jump[2], " end\n")
          end
        elseif op == "LE" then
          i = i + 1
          local jump = codes[i]
          assert(jump[1] == "JMP")
          if code[2] == 0 then
            out:write("if not (L:get(", code[3], ") <= L:get(", code[4], ")) then goto L", jump[2], " end\n")
          else
            out:write("if L:get(", code[3], ") <= L:get(", code[4], ") then goto L", jump[2], " end\n")
          end
        elseif op == "RETURN" then
          out:write("return L:RETURN(", code[2], ", ", code[3], ")\n")
        else
          out:write("L:", code[1], "(")
          for i = 2, #code do
            if i > 2 then
              out:write(", ")
            end
            out:write(code[i])
          end
          out:write(")\n")
        end
        i = i + 1
      end
    end

    out:write("end\n")
    out:write("L.protos[", i, "] = proto\n")
  end

  out:write("L:CLOSURE(", root.r, ", ", #protos, ")\n")
  out:write("L:CALL(", root.r, ", 1)\n")
end
