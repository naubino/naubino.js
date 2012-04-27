(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  define(["Layer", "Naub", "Graph", "Shapes"], function(Layer, Naub, Graph, _arg) {
    var Ball, Clock, Frame, FrameCircle, Game, NumberShape, PauseButton, PlayButton, Square, StringShape;
    Ball = _arg.Ball, Square = _arg.Square, Frame = _arg.Frame, FrameCircle = _arg.FrameCircle, Clock = _arg.Clock, NumberShape = _arg.NumberShape, StringShape = _arg.StringShape, PlayButton = _arg.PlayButton, PauseButton = _arg.PauseButton;
    return Game = (function(_super) {

      __extends(Game, _super);

      function Game(canvas) {
        this.create_naub_triple = __bind(this.create_naub_triple, this);
        this.create_naub_pair = __bind(this.create_naub_pair, this);        Game.__super__.constructor.call(this, canvas);
        this.name = "game";
        this.graph = new Graph(this);
        this.animation.name = "game.animation";
        this.drawing = true;
        this.focused_naub = null;
        this.gravity = Naubino.settings.physics.gravity.game;
        this.joining_allowed = true;
        console.log("mousemove");
        Naubino.mousemove.add(this.move_pointer);
        Naubino.mousedown.add(this.click);
        Naubino.mouseup.add(this.unfocus);
        this.naub_replaced = new Naubino.Signal();
        this.naub_joined = new Naubino.Signal();
        this.naub_destroyed = new Naubino.Signal();
        this.cycle_found = new Naubino.Signal();
        this.naub_focused = new Naubino.Signal();
        this.naub_unfocused = new Naubino.Signal();
        StateMachine.create({
          target: this,
          events: Naubino.settings.events
        });
      }

      Game.prototype.onplaying = function() {
        this.animation.play();
        return this.start_stepper();
      };

      Game.prototype.onleaveplaying = function(e, f, t) {
        return this.stop_stepper();
      };

      Game.prototype.onpaused = function(e, f, t) {
        return this.animation.pause();
      };

      Game.prototype.onstopped = function(e, f, t) {};

      Game.prototype.create_some_naubs = function(n) {
        var _i, _results;
        if (n == null) n = 1;
        _results = [];
        for (_i = 1; 1 <= n ? _i <= n : _i >= n; 1 <= n ? _i++ : _i--) {
          this.create_naub_pair();
          _results.push(this.create_naub_triple());
        }
        return _results;
      };

      Game.prototype.create_matching_naubs = function(n, extras) {
        var a, b, colors, i, x, y, _i, _j, _ref, _ref2, _ref3, _results;
        if (n == null) n = 1;
        if (extras == null) extras = 0;
        for (_i = 1; 1 <= n ? _i <= n : _i >= n; 1 <= n ? _i++ : _i--) {
          colors = Util.shuffle([0, 1, 2, 3, 4, 5]);
          colors[5] = colors[0];
          i = 0;
          while (i < colors.length - 1) {
            _ref = this.random_outside(), x = _ref.x, y = _ref.y;
            _ref2 = this.create_naub_pair(x, y, colors[i], colors[i + 1]), a = _ref2[0], b = _ref2[1];
            i++;
          }
        }
        if (extras > 0) {
          _results = [];
          for (_j = 1; 1 <= extras ? _j <= extras : _j >= extras; 1 <= extras ? _j++ : _j--) {
            _ref3 = this.random_outside(), x = _ref3.x, y = _ref3.y;
            _results.push(this.create_naub_pair(x, y));
          }
          return _results;
        }
      };

      Game.prototype.create_naub_pair = function(x, y, color_a, color_b) {
        var dir, naub_a, naub_b, _ref;
        if (x == null) x = null;
        if (y == null) y = x;
        if (color_a == null) color_a = null;
        if (color_b == null) color_b = null;
        if (x == null) _ref = this.random_outside(), x = _ref.x, y = _ref.y;
        naub_a = new Naub(this, color_a);
        naub_b = new Naub(this, color_b);
        color_a = naub_a.color_id;
        color_b = naub_b.color_id;
        naub_a.add_shape(new Ball);
        naub_b.add_shape(new Ball);
        color_a = naub_a.color_id;
        color_b = naub_b.color_id;
        this.add_object(naub_a);
        this.add_object(naub_b);
        naub_a.update();
        naub_b.update();
        dir = Math.random() * Math.PI;
        naub_a.physics.pos.Set(x, y);
        naub_b.physics.pos.Set(x, y);
        naub_a.physics.pos.AddPolar(dir, 15);
        naub_b.physics.pos.AddPolar(dir, -15);
        naub_a.join_with(naub_b);
        return [color_a, color_b];
      };

      Game.prototype.create_naub_triple = function(x, y, color_a, color_b, color_c) {
        var dir, naub_a, naub_b, naub_c, _ref;
        if (x == null) x = null;
        if (y == null) y = x;
        if (color_a == null) color_a = null;
        if (color_b == null) color_b = null;
        if (color_c == null) color_c = null;
        if (x == null) _ref = this.random_outside(), x = _ref.x, y = _ref.y;
        naub_a = new Naub(this, color_a);
        naub_b = new Naub(this, color_b);
        naub_c = new Naub(this, color_c);
        naub_a.add_shape(new Ball);
        naub_b.add_shape(new Ball);
        naub_c.add_shape(new Ball);
        this.add_object(naub_a);
        this.add_object(naub_b);
        this.add_object(naub_c);
        naub_a.update();
        naub_b.update();
        naub_c.update();
        dir = Math.random() * Math.PI;
        naub_a.physics.pos.Set(x, y);
        naub_b.physics.pos.Set(x, y);
        naub_c.physics.pos.Set(x, y);
        naub_a.physics.pos.AddPolar(dir, 30);
        naub_c.physics.pos.AddPolar(dir, -30);
        naub_a.join_with(naub_b);
        return naub_b.join_with(naub_c);
      };

      Game.prototype.random_outside = function() {
        var offset, seed, x, y;
        offset = 100;
        seed = Math.round((Math.random() * 3) + 1);
        switch (seed) {
          case 1:
            x = this.width + offset;
            y = this.height * Math.random();
            break;
          case 2:
            x = this.width * Math.random();
            y = this.height + offset;
            break;
          case 3:
            x = 0 - offset;
            y = this.height * Math.random();
            break;
          case 4:
            x = this.width * Math.random();
            y = 0 - offset;
        }
        return {
          x: x,
          y: y
        };
      };

      Game.prototype.count_basket = function() {
        var count, diff, id, naub, _ref;
        count = [];
        if (this.basket_size != null) {
          _ref = this.objects;
          for (id in _ref) {
            naub = _ref[id];
            diff = this.center.Copy();
            diff.Subtract(naub.physics.pos);
            if (diff.Length() < this.basket_size - naub.size / 2) count.push(naub);
          }
        }
        return count;
      };

      Game.prototype.capacity = function() {
        var filling, naub, r, size, _i, _len, _ref;
        r = this.basket_size;
        size = Math.ceil(r * r * Math.PI * 0.75);
        filling = 0;
        _ref = this.count_basket();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          naub = _ref[_i];
          filling += naub.area();
        }
        return 100 - Math.ceil(filling * 100 / size);
      };

      Game.prototype.destroy_naubs = function(list) {
        var i, naub, one_after_another, _i, _len,
          _this = this;
        for (_i = 0, _len = list.length; _i < _len; _i++) {
          naub = list[_i];
          this.get_object(naub).disable();
        }
        i = 0;
        one_after_another = function() {
          if (i < list.length) {
            _this.get_object(list[i]).destroy();
            i++;
          }
          return setTimeout(one_after_another, 40);
        };
        return one_after_another();
      };

      Game.prototype.check_joining = function(naub, other) {
        var alone, close_related, id, joined, naub_partners, other_alone, other_partners, partner, same_color;
        if (naub.number === other.number || !this.joining_allowed) return false;
        naub_partners = (function() {
          var _ref, _results;
          _ref = naub.joins;
          _results = [];
          for (id in _ref) {
            partner = _ref[id];
            _results.push(partner.number);
          }
          return _results;
        })();
        other_partners = (function() {
          var _ref, _results;
          _ref = other.joins;
          _results = [];
          for (id in _ref) {
            partner = _ref[id];
            _results.push(partner.number);
          }
          return _results;
        })();
        close_related = naub_partners.some(function(x) {
          return __indexOf.call(other_partners, x) >= 0;
        });
        joined = naub.is_joined_with(other);
        alone = Object.keys(naub.joins).length === 0;
        other_alone = Object.keys(other.joins).length === 0;
        same_color = naub.color_id === other.color_id;
        if (!naub.disabled && !joined && same_color && !close_related && !alone && !other_alone) {
          other.replace_with(naub);
          return true;
        } else if (alone && !(other.disabled || naub.disabled)) {
          naub.join_with(other);
          return true;
        }
        return false;
      };

      Game.prototype.draw = function() {
        var id, obj, _ref, _ref2;
        this.ctx.clearRect(0, 0, Naubino.settings.canvas.width, Naubino.settings.canvas.height);
        this.ctx.save();
        _ref = this.objects;
        for (id in _ref) {
          obj = _ref[id];
          obj.draw_joins(this.ctx);
        }
        _ref2 = this.objects;
        for (id in _ref2) {
          obj = _ref2[id];
          obj.draw(this.ctx);
        }
        return this.ctx.restore();
      };

      Game.prototype.clear_objects = function() {
        Game.__super__.clear_objects.call(this);
        return this.graph.clear();
      };

      Game.prototype.step = function(dt) {
        var id, obj, other, _ref, _ref2;
        this.naub_forces(dt);
        if (this.mousedown && this.focused_naub) {
          this.focused_naub.physics.follow(this.pointer.Copy());
          _ref = this.objects;
          for (id in _ref) {
            other = _ref[id];
            if ((this.focused_naub.distance_to(other)) < (this.focused_naub.size + Naubino.settings.naub.fondness)) {
              this.check_joining(this.focused_naub, other);
              break;
            }
          }
        }
        _ref2 = this.objects;
        for (id in _ref2) {
          obj = _ref2[id];
          if (obj.removed) {
            this.remove_obj(id);
            return 42;
          }
        }
      };

      Game.prototype.naub_forces = function(dt) {
        var id, naub, other, _i, _ref, _ref2, _ref3, _results;
        _ref = this.objects;
        _results = [];
        for (id in _ref) {
          naub = _ref[id];
          naub.physics.gravitate(dt);
          _ref2 = naub.joins;
          for (id in _ref2) {
            other = _ref2[id];
            naub.physics.join_springs(other);
          }
          for (_i = 0; _i <= 3; _i++) {
            _ref3 = this.objects;
            for (id in _ref3) {
              other = _ref3[id];
              naub.physics.collide(other);
            }
          }
          _results.push(naub.step(dt));
        }
        return _results;
      };

      return Game;

    })(Layer);
  });

}).call(this);
