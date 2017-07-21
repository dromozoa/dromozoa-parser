local print = print

local metatable = {}

function metatable:__index(key)
  print("__index", key)
  return key
end
setmetatable(_G, metatable)

function metatable:__newindex(key, value)
  print("__index", key, value)
end

_.decimal = R"19" * R"09"^"*"
_.octal = P"0" * R"07"

scanner {
  S" \t\n\v\f\r"^"+" { "skip" };
  decimal;
  octal;
  hexadecimal;
  "*";
  "+";
  "(";
  ")";
  R"az__" * R"09az__"^"*";
  P"\"" { "call", "string" }
}

scanner "string" {
  P"\"" { ret; };
  P"\\."
}

main = {
  S " \t\n\v\f\r" ^ "+" { skip };
  decimal;
  octal;
  hexadecimal;
  "*";
  "+";
}

_"E"
  :_ "E" "*" "E"
  :_ "E" "+" "E"





