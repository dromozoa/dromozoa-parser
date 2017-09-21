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

  function Closure(proto, stack, top, parent) {
    this.proto = proto;
    this.stack = stack;
    this.top = top;
    this.parent = parent;
  }

  prototype = Closure.prototype;

  prototype.getconst = function (index) {
    return this.proto.constants[index];
  };

  prototype.getupval = function (index) {
    var that = this;
    var upvalue;
    var key;
    do {
      upvalue = that.proto.upvalues[index];
      key = upvalue[0]
      index = upvalue[1]
      if (key === "A") {
        return that.stack[index];
      }
      if (key === "B") {
        return that.stack[that.top + index];
      }
      that = that.parent;
    } while (that !== undefined);
  };

  prototype.setupval = function (index, value) {
    var that = this;
    var upvalue;
    var key;
    do {
      upvalue = that.proto.upvalues[index];
      key = upvalue[0]
      index = upvalue[1]
      if (key === "A") {
        that.stack[index] = value;
        return;
      }
      if (key === "B") {
        that.stack[that.top + index] = value;
        return;
      }
    } while (that !== undefined);
  };

  function State(chunk, stack, top) {
    if (stack === undefined) {
      stack = [];
    }
    if (top === undefined) {
      top = 0;
    }
    this.chunk = chunk;
    this.stack = stack;
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
    return new Closure(this.chunk.protos[index], this.stack, this.top, this.running);
  };

  prototype.newstack = function () {
    return [];
  };

  prototype.call = function (closure) {
    this.frames.push({
      stack: this.stack,
      top: this.top,
      running: this.running
    });
    this.stack = this.S;
    this.top = this.S.length;
    this.running = closure;
    delete this.T;
    delete this.S;
    this.running.proto(this);
  };

  prototype.ret = function (n) {
    var frame = this.frames.pop();
    this.stack = frame.stack;
    this.top = frame.top;
    this.running = frame.running;
    if (n > 0) {
      this.T = this.S;
    } else {
      this.T = [];
    }
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
    return this.running.getconst(index);
  };

  prototype.getupval = function (index) {
    return this.running.getupval(index);
  };

  prototype.setupval = function (index, value) {
    this.running.setupval(index, value);
  };

  prototype.push_vararg = function (stack) {
    var i = this.running.proto.A;
    while (i < this.top) {
      stack.push(this.stack[i]);
      i += 1;
    }
  };

  prototype.push_result = function (stack) {
    var i = 0;
    while (i < this.T.length) {
      stack.push(this.T[i])
      i += 1;
    }
  };

  prototype.len = function (that) {
    var type = typeof that;
    if (type === "string") {
      return that.length;
    } else {
      return that.length();
    }
  };

  prototype.print = new Closure(function (L) {
    var args = [];
    var i = 0;
    while (i < L.top) {
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
