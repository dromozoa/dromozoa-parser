/*jslint this,white*/
"use strict";
(function (root) {
  var lua = root.dromozoa.parser.lua;
  var chunk = root.dromozoa.parser.chunk;
  var L = new lua.State(chunk);
  chunk(L);
}(this.self));
