

-- _G = {}

_"decimal" = R"19" * R"09"^"*"
_"octal" = P"0" * R"07"^"*"
_"hexadecimal" = (P"0x" * R"09af"):opt("i")

_"main" {
  S" \t\n\v\f\r"^"+" { "skip" };
  _"decimal";
  _"octal";
  _"hexadecimal";
  P"*";
  P"+";
  P"(";
  P")";
  R"az__" * R"09az__"^"*" :as "identifier";
  P"\"" { "call", "string" };
  P"[" { "call", "bracket" };
}

_"E"
  :_ "E" "*" "E"
  :_ "E" "+" "E"

