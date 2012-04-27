(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(function() {
    var Graph;
    return Graph = (function() {

      function Graph(layer) {
        this.layer = layer;
        this.cycle_test = __bind(this.cycle_test, this);
        this.join_id_sequence = 0;
        this.naubs = [];
        this.joins = {};
      }

      Graph.prototype.update_naub_list = function() {
        var i, id, join, _ref, _results;
        this.naubs = [];
        _ref = this.joins;
        _results = [];
        for (id in _ref) {
          join = _ref[id];
          _results.push((function() {
            var _ref2, _results2;
            _results2 = [];
            for (i = 0; i <= 1; i++) {
              if (_ref2 = join[i], __indexOf.call(this.naubs, _ref2) < 0) {
                _results2.push(this.naubs.push(join[i]));
              } else {
                _results2.push(void 0);
              }
            }
            return _results2;
          }).call(this));
        }
        return _results;
      };

      Graph.prototype.add_join = function(a, b) {
        var join;
        this.join_id_sequence++;
        join = [a.number, b.number];
        this.joins[this.join_id_sequence] = join;
        this.update_naub_list();
        return this.join_id_sequence;
      };

      Graph.prototype.remove_join = function(id) {
        delete this.joins[id];
        return this.update_naub_list();
      };

      Graph.prototype.clear = function() {
        this.join_id_sequence = 0;
        this.naubs = [];
        return this.joins = {};
      };

      Graph.prototype.join_list = function() {
        var id, join, _ref, _results;
        console.log("joinList");
        _ref = this.joins;
        _results = [];
        for (id in _ref) {
          join = _ref[id];
          _results.push(console.log(id + " " + join));
        }
        return _results;
      };

      Graph.prototype.dotty = function() {
        var dot, id, join, joins;
        dot = "graph G {\n";
        joins = (function() {
          var _ref, _results;
          _ref = this.joins;
          _results = [];
          for (id in _ref) {
            join = _ref[id];
            _results.push(join[0] + " -- " + join[1]);
          }
          return _results;
        }).call(this);
        dot += joins.join("\n") + "}";
        return console.log(dot);
      };

      Graph.prototype.partners = function(naub, pre) {
        var id, join, partners, _ref;
        if (pre == null) pre = null;
        partners = [];
        _ref = this.joins;
        for (id in _ref) {
          join = _ref[id];
          if (__indexOf.call(join, naub) >= 0) {
            if (__indexOf.call(join, pre) < 0) {
              partners.push(join[(join.indexOf(naub)) ^ 1]);
            }
          }
        }
        return partners;
      };

      Graph.prototype.cycle_test = function(first) {
        var color, cycles, dfs_cycle, dfs_num, inaub, naub, _i, _len, _ref, _ref2, _ref3;
        cycles = [];
        this.dfs_map = [];
        _ref = this.naubs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          inaub = _ref[_i];
          this.dfs_map[inaub] = {
            naub: inaub,
            dfs_num: 0,
            color: 0
          };
        }
        this.seq_num = 1;
        _ref2 = this.dfs_map;
        for (inaub in _ref2) {
          _ref3 = _ref2[inaub], naub = _ref3.naub, dfs_num = _ref3.dfs_num, color = _ref3.color;
          if (dfs_num === 0) {
            dfs_cycle = this.dfs(naub, null, first);
            cycles = cycles.filter(function(x) {
              return __indexOf.call(dfs_cycle, x) >= 0;
            });
          }
        }
      };

      Graph.prototype.dfs = function(naub, pre, first) {
        var cycles, list, partner, _i, _len, _ref;
        if (pre == null) pre = null;
        if (first == null) first = null;
        cycles = [];
        this.dfs_map[naub].dfs_num = this.seq_num;
        this.seq_num++;
        this.dfs_map[naub].color = 1;
        _ref = this.partners(naub, pre);
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          partner = _ref[_i];
          if (this.dfs_map[partner].dfs_num === 0) {
            cycles = this.dfs(partner, naub, first).filter(function(x) {
              return __indexOf.call(cycles, x) >= 0;
            });
          }
          if (this.dfs_map[partner].color === 1) {
            list = this.cycle_list(naub, partner, first);
            if (list.length > 0) this.layer.cycle_found.dispatch(list);
          }
        }
        this.dfs_map[naub].color = 2;
        return cycles;
      };

      Graph.prototype.cycle_list = function(v, w, first) {
        var cycle, cycle_naubs, i, x,
          _this = this;
        if (first == null) first = null;
        cycle = this.dfs_map.filter(function(_arg) {
          var color, dfs_num;
          dfs_num = _arg.dfs_num, color = _arg.color;
          return dfs_num >= _this.dfs_map[w].dfs_num && color === 1;
        });
        cycle.sort(function(a, b) {
          return a.dfs_num - b.dfs_num;
        });
        cycle_naubs = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = cycle.length; _i < _len; _i++) {
            x = cycle[_i];
            _results.push(x.naub);
          }
          return _results;
        })();
        if ((first != null) && __indexOf.call(cycle_naubs, first) >= 0) {
          cycle_naubs = cycle_naubs;
          i = cycle_naubs.indexOf(first);
          cycle_naubs = cycle_naubs.slice(i, cycle_naubs.length).concat(cycle_naubs.slice(0, i));
        }
        return cycle_naubs;
      };

      return Graph;

    })();
  });

}).call(this);
