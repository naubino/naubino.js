(function() {

  window.Util = {
    shuffle: function(a) {
      var b, i, j, x, _len, _ref;
      b = a.slice();
      for (i = 0, _len = b.length; i < _len; i++) {
        x = b[i];
        j = Math.floor(Math.random() * b.length);
        _ref = [b[j], b[i]], b[i] = _ref[0], b[j] = _ref[1];
      }
      return b;
    },
    extend: function(obj, mixin) {
      var method, name, _results;
      _results = [];
      for (name in mixin) {
        method = mixin[name];
        _results.push(obj[name] = method);
      }
      return _results;
    },
    include: function(klass, mixin) {
      return this.extend(klass.prototype, mixin);
    }
  };

}).call(this);
