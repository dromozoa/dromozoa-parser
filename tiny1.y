%start value

%%

value /* comment */
  : array
  | NUMBER
  | TRUE
  | FALSE
  ;

array
  : ARRAY_BEGIN ARRAY_END
  | ARRAY_BEGIN array_item_list ARRAY_END
  ;

array_item_list
  : array_item
  | array_item SEPARATOR array_item_list
  ;

array_item
  : value
  ;
