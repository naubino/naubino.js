(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(function() {
    var Layer;
    return Layer = (function() {

      function Layer(canvas) {
        var _this = this;
        this.canvas = canvas;
        this.color_to_rgba = __bind(this.color_to_rgba, this);
        this.move_pointer = __bind(this.move_pointer, this);
        this.unfocus = __bind(this.unfocus, this);
        this.click = __bind(this.click, this);
        this.do_draw = __bind(this.do_draw, this);
        this.do_step = __bind(this.do_step, this);
        this.stop_stepper = __bind(this.stop_stepper, this);
        this.start_stepper = __bind(this.start_stepper, this);
        this.width = this.canvas.width;
        this.height = this.canvas.height;
        this.center = new b2Vec2(this.width / 2, this.height / 2);
        this.ctx = this.canvas.getContext('2d');
        this.pointer = this.center.Copy();
        this.objects = {};
        this.objects_count = 0;
        this.physics_fps = Naubino.settings.physics.fps;
        this.fps = Naubino.settings.graphics.fps;
        this.dt = Naubino.settings.physics.fps / 1000 * Naubino.settings.physics.calming_const;
        this.time = Date.now();
        this.cut = 0;
        this.show();
        this.animation = {
          parent: this,
          start_timer: function() {
            return _this.draw_loop = setInterval(_this.do_draw, 1000 / _this.fps);
          },
          stop_timer: function() {
            return clearInterval(_this.draw_loop);
          }
        };
        StateMachine.create({
          target: this.animation,
          initial: 'stopped',
          events: Naubino.settings.layer_events,
          callbacks: {
            error: function(e, from, to, args, code, msg) {
              return console.error("" + this.name + "." + e + ": " + from + " -> " + to + "\n" + code + "::" + msg);
            },
            onbeforeplay: function(e, f, t) {
              return this.start_timer();
            },
            onbeforepause: function(e, f, t) {
              return this.stop_timer();
            },
            onbeforestop: function(e, f, t) {
              this.stop_timer();
              return this.parent.clear();
            },
            onchangestate: function(e, f, t) {}
          }
        });
      }

      /* overwrite these
      */

      Layer.prototype.draw = function() {};

      Layer.prototype.step = function(dt) {};

      Layer.prototype.get_dt = function() {
        var old_time;
        old_time = this.time;
        this.time = Date.now();
        return this.time - old_time;
      };

      Layer.prototype.start_stepper = function() {
        return this.loop = setInterval(this.do_step, 1000 / this.physics_fps);
      };

      Layer.prototype.stop_stepper = function() {
        return clearInterval(this.loop);
      };

      Layer.prototype.do_step = function() {
        return this.step(this.dt);
      };

      Layer.prototype.do_draw = function() {
        if (this.drawing) return this.draw();
      };

      /* managing objects
      */

      Layer.prototype.add_object = function(obj) {
        obj.center = this.center;
        this.objects_count++;
        obj.number = this.objects_count;
        this.objects[this.objects_count] = obj;
        return this.objects_count;
      };

      Layer.prototype.get_object = function(id) {
        return this.objects[id];
      };

      Layer.prototype.remove_obj = function(id) {
        return delete this.objects[id];
      };

      Layer.prototype.clear_objects = function() {
        return this.objects = {};
      };

      Layer.prototype.for_each = function(callback) {
        var k, v, _ref, _results;
        _ref = this.objects;
        _results = [];
        for (k in _ref) {
          v = _ref[k];
          _results.push(callback(v));
        }
        return _results;
      };

      Layer.prototype.fade_in = function(callback) {
        var fade,
          _this = this;
        if (callback == null) callback = null;
        console.log("fade in", this.fadeloop);
        this.canvas.style.opacity = 0.01;
        if (this.backup_ctx != null) this.restore();
        fade = function() {
          if ((_this.canvas.style.opacity *= 1.2) >= 1) {
            clearInterval(_this.fadeloop);
            console.log("done");
            _this.show();
            if (callback != null) return callback.call();
          }
        };
        clearInterval(this.fadeloop);
        return console.log(this.fadeloop = setInterval(fade, 40));
      };

      Layer.prototype.fade_out = function(callback) {
        var fade,
          _this = this;
        if (callback == null) callback = null;
        console.log("fade out", this.fadeloop);
        this.cache();
        fade = function() {
          if ((_this.canvas.style.opacity *= 0.8) <= 0.05) {
            clearInterval(_this.fadeloop);
            _this.hide();
            if (callback != null) return callback.call();
          }
        };
        clearInterval(this.fadeloop);
        return console.log(this.fadeloop = setInterval(fade, 40));
      };

      Layer.prototype.show = function() {
        return this.canvas.style.opacity = 1;
      };

      Layer.prototype.hide = function() {
        return this.canvas.style.opacity = 0;
      };

      Layer.prototype.clear = function() {
        return this.canvas.width = this.canvas.width;
      };

      Layer.prototype.cache = function() {
        return this.backup_ctx = this.ctx;
      };

      Layer.prototype.restore = function() {
        return this.ctx = this.backup_ctx;
      };

      Layer.prototype.click = function(x, y) {
        var naub, _ref;
        this.mousedown = true;
        _ref = [x, y], this.pointer.x = _ref[0], this.pointer.y = _ref[1];
        naub = this.get_obj(x, y);
        if (naub) {
          naub.focus();
          return this.focused_naub = naub;
        }
      };

      Layer.prototype.unfocus = function() {
        this.mousedown = false;
        if (this.focused_naub) this.focused_naub.unfocus();
        return this.focused_naub = null;
      };

      Layer.prototype.move_pointer = function(x, y) {
        var _ref;
        if (this.mousedown) {
          return _ref = [x, y], this.pointer.x = _ref[0], this.pointer.y = _ref[1], _ref;
        }
      };

      Layer.prototype.get_obj = function(x, y) {
        var id, obj, _ref;
        _ref = this.objects;
        for (id in _ref) {
          obj = _ref[id];
          if (obj.isHit(x, y) && obj.isClickable) return obj;
        }
      };

      /* utils
      */

      Layer.prototype.color_to_rgba = function(color, shift) {
        var a, b, g, r;
        if (shift == null) shift = 0;
        r = Math.round(color[0] + shift);
        g = Math.round(color[1] + shift);
        b = Math.round(color[2] + shift);
        a = color[3];
        return "rgba(" + r + "," + g + "," + b + "," + a + ")";
      };

      return Layer;

    })();
  });

}).call(this);
