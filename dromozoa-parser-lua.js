/*jslint this,white*/
"use strict";
(function (root) {
  var console = root.console;
  var prototype;

  function Table() {
    this.number_table = {};
    this.string_table = {};
  }

  prototype = Table.prototype;

  prototype.get = function (key) {
    var type = typeof key;
    if (type === "number") {
      return this.number_table[key];
    }
    if (type === "string") {
      return this.string_table[key];
    }
  };

  prototype.set = function (key, value) {
    var type = typeof key;
    if (type === "number") {
      this.number_table[key] = value;
    }
    if (type === "string") {
      this.string_table[key] = value;
    }
  };

  prototype.length = function () {
    var i = 1;
    while (this.number_table[i] !== undefined) {
      i += 1;
    }
    return i - 1;
  };

  function Closure(proto, stack, base, top, parent) {
    this.proto = proto;
    this.stack = stack;
    this.base = base;
    this.top = top;
    this.parent = parent;
  }

  function State(chunk, stack, base, top) {
    if (stack === undefined) {
      stack = [ undefined ];
    }
    if (base === undefined) {
      base = -1;
    }
    if (top === undefined) {
      top = 1;
    }
    this.chunk = chunk;
    this.stack = stack;
    this.base = base;
    this.top = top;
    this.frames = [];
  }

  prototype = State.prototype;

  prototype.newtable = function () {
    return new Table();
  };

  prototype.settable = function (table, key, value) {
    table.set(key, value);
  };

  prototype.gettable = function (table, key) {
    return table.get(key);
  };

  prototype.closure = function (index) {
    return new Closure(this.chunk.protos[index], this.stack, this.base, this.top, this.running);
  };

  prototype.newstack = function () {
    return [];
  };

  prototype.call = function (closure) {
    this.frames.push({
      stack: this.stack,
      base: this.base,
      top: this.top,
      running: this.running
    });
    this.stack = this.S;
    this.base = -1;
    this.top = this.S.length - 1;
    this.running = closure;
    delete this.T;
    delete this.S;
    this.running.proto(this);
  };

  prototype.ret = function () {
    var frame = this.frames.pop();
    this.stack = frame.stack;
    this.base = frame.base;
    this.top = frame.top;
    this.running = frame.running;
    delete this.S;
  };

  prototype.setlist = function (table) {
    var i = 1;
    while (i <= this.S.length) {
      table.set(i, this.S[i - 1]);
      i += 1;
    }
  }

  prototype.getconst = function (index) {
    return this.running.proto.constants[index];
  };

  prototype.getupval = function (index) {
    var closure = this.running;
    var upvalue;
    var key;
    do {
      upvalue = closure.proto.upvalues[index];
      key = upvalue[0];
      if (key === "A") {
        return closure.stack[closure.base + upvalue[1]];
      }
      if (key === "B") {
        return closure.stack[closure.top + upvalue[1]];
      }
      index = upvalue[1];
      closure = closure.parent;
    } while (closure !== undefined);
  };

  prototype.setupval = function (index, value) {
    var closure = this.running;
    var upvalue;
    var key;
    do {
      upvalue = closure.proto.upvalues[index];
      key = upvalue[0];
      if (key === "A") {
        closure.stack[closure.base + upvalue[1]] = value;
        return;
      }
      if (key === "B") {
        closure.stack[closure.top + upvalue[1]] = value;
        return;
      }
      index = upvalue[1];
      closure = closure.parent;
    } while (closure !== undefined);
  };

  prototype.push_vararg = function (stack) {
    var i = this.running.proto.A + 1;
    while (i <= this.top) {
      stack.push(this.stack[i]);
      i += 1;
    }
  };

  prototype.print = new Closure(function (L) {
    var args = [];
    var i = L.base + 1;
    while (i <= L.top) {
      args.push(L.stack[i]);
      i += 1;
    }
    console.log.apply(console, args);
    return L.ret(0);
  });

  if (!root.dromozoa) {
    root.dromozoa = {};
  }
  if (!root.dromozoa.parser) {
    root.dromozoa.parser = {};
  }
  root.dromozoa.parser.lua = {
    Table: Table,
    State: State
  };
}(this.self));
