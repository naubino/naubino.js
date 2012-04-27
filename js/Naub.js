(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  define(["PhysicsModel"], function(PhysicsModel) {
    var Naub;
    return Naub = (function() {

      function Naub(layer, color_id, size) {
        this.layer = layer;
        this.color_id = color_id != null ? color_id : null;
        this.size = size != null ? size : Naubino.settings.naub.size;
        this.color_to_rgba = __bind(this.color_to_rgba, this);
        this.remove = __bind(this.remove, this);
        this.draw_joins = __bind(this.draw_joins, this);
        this.physics = new PhysicsModel(this);
        this.physics.attracted_to = this.layer.center.Copy();
        this.ctx = this.layer.ctx;
        this.frame = this.size * 1.5;
        if (this.color_id == null) this.color_id = this.random_palette_color();
        this.life_rendering = false;
        this.removed = false;
        this.focused = false;
        this.disabled = false;
        this.isClickable = true;
        this.shapes = [];
        this.joins = {};
        this.drawing_join = {};
        this.join_style = {
          fill: [0, 0, 0, 1],
          width: 6
        };
        this.update();
      }

      Naub.prototype.draw = function(ctx) {
        var pos, x, y;
        pos = this.physics.pos;
        if (!(Naubino.settings.graphics.updating || this.life_rendering)) {
          ctx.save();
          x = pos.x - this.frame;
          y = pos.y - this.frame;
          this.ctx.drawImage(this.buffer, x, y);
          return this.ctx.restore();
        } else {
          return this.render(this.ctx, pos.x, pos.y);
        }
      };

      Naub.prototype.update = function() {
        var b_ctx;
        this.buffer = document.createElement('canvas');
        this.buffer.width = this.buffer.height = this.frame * 2;
        b_ctx = this.buffer.getContext('2d');
        return this.render(b_ctx, this.frame, this.frame);
      };

      Naub.prototype.resize = function(size) {
        var attracted_to, force, pos, vel, _ref;
        if (size == null) size = null;
        this.size = size != null ? size : Naubino.settings.naub.size;
        this.frame = this.size * 1.5;
        _ref = this.physics, pos = _ref.pos, vel = _ref.vel, force = _ref.force, attracted_to = _ref.attracted_to;
        this.physics = new PhysicsModel(this);
        Util.extend(this.physics, {
          pos: pos,
          vel: vel,
          force: force,
          attracted_to: attracted_to
        });
        return this.update();
      };

      Naub.prototype.render = function(ctx, x, y) {
        var shape, _i, _len, _ref, _results;
        _ref = this.shapes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          shape = _ref[_i];
          _results.push(shape.render(ctx, x, y));
        }
        return _results;
      };

      Naub.prototype.add_shape = function(shape) {
        shape.setup(this);
        return this.shapes.push(shape);
      };

      Naub.prototype.update_shapes = function() {
        var shape, _i, _len, _ref, _results;
        _ref = this.shapes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          shape = _ref[_i];
          _results.push(shape.setup(this));
        }
        return _results;
      };

      Naub.prototype.area = function() {
        var r;
        r = this.size * this.physics.margin;
        return Math.floor(r * r * Math.PI);
      };

      Naub.prototype.real_area = function() {
        var shape, _i, _len, _ref;
        _ref = this.shapes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          shape = _ref[_i];
          if (shape.area) return shape.area();
        }
        return 0;
      };

      Naub.prototype.draw_joins = function(context) {
        var id, partner, _ref;
        _ref = this.joins;
        for (id in _ref) {
          partner = _ref[id];
          if (this.drawing_join[id]) this.draw_join(context, partner);
        }
      };

      Naub.prototype.draw_join = function(ctx, partner) {
        var diff, fiber, l, m, pos, pos2, stretch, stretched_width;
        pos = this.physics.pos;
        pos2 = partner.physics.pos;
        diff = pos2.Copy();
        diff.Subtract(pos);
        l = diff.Length();
        m = this.physics.margin * 25;
        fiber = 10;
        stretch = (m + fiber) / (l + fiber);
        stretch = Math.round(stretch * 10) / 10;
        stretched_width = this.join_style.width * stretch;
        ctx.save();
        ctx.strokeStyle = this.color_to_rgba(this.join_style.fill);
        try {
          ctx.beginPath();
          ctx.moveTo(pos.x, pos.y);
          ctx.lineTo(pos2.x, pos2.y);
          ctx.lineWidth = stretched_width;
          ctx.lineCap = "round";
          ctx.stroke();
          ctx.closePath();
          return ctx.restore();
        } catch (e) {
          return this.layer.menu_pause.dispatch();
        }
      };

      Naub.prototype.step = function(dt) {
        return this.physics.step(dt);
      };

      Naub.prototype.disable = function() {
        this.disabled = true;
        return this.update();
      };

      Naub.prototype.enable = function() {
        this.disabled = false;
        return this.update();
      };

      Naub.prototype.grey_out = function() {
        return this.style.fill = [100, 100, 100, 1];
      };

      Naub.prototype.recolor = function() {
        return this.style.fill = Naubino.colors[this.color_id];
      };

      Naub.prototype.remove = function() {
        var id, naub, _ref, _results;
        this.removed = true;
        _ref = this.joins;
        _results = [];
        for (id in _ref) {
          naub = _ref[id];
          delete naub.joins[id];
          _results.push(this.layer.graph.remove_join(id));
        }
        return _results;
      };

      Naub.prototype.destroy = function() {
        var id, partner, shape, _i, _len, _ref, _ref2;
        _ref = this.joins;
        for (id in _ref) {
          partner = _ref[id];
          this.drawing_join[id] = true;
          partner.drawing_join[id] = false;
        }
        this.destroying = true;
        this.shapes[0].destroy_animation(this.remove);
        _ref2 = this.shapes.slice(1);
        for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
          shape = _ref2[_i];
          shape.destroy_animation();
        }
        return this.layer.naub_destroyed.dispatch(this.number);
      };

      Naub.prototype.join_with = function(other) {
        var join;
        join = this.layer.graph.add_join(this, other);
        this.joins[join] = other;
        this.drawing_join[join] = true;
        other.joins[join] = this;
        other.drawing_join[join] = false;
        if (this.layer.naub_joined != null) this.layer.naub_joined.dispatch();
        return join;
      };

      Naub.prototype.replace_with = function(other) {
        var id, naub, remove_joins;
        remove_joins = (function() {
          var _ref, _results;
          _ref = this.joins;
          _results = [];
          for (id in _ref) {
            naub = _ref[id];
            other.join_with(naub);
            delete naub.joins[id];
            _results.push(this.layer.graph.remove_join(id));
          }
          return _results;
        }).call(this);
        this.layer.unfocus();
        this.remove();
        this.layer.naub_replaced.dispatch(other.number);
        return 42;
      };

      Naub.prototype.is_joined_with = function(other) {
        var id, joined, opnaub, _ref;
        joined = false;
        _ref = this.joins;
        for (id in _ref) {
          opnaub = _ref[id];
          if (opnaub === other) joined = true;
        }
        return joined;
      };

      Naub.prototype.joined_naubs = function() {
        var id, list, naub, _ref;
        list = [];
        _ref = this.joins;
        for (id in _ref) {
          naub = _ref[id];
          list.push(naub.number);
        }
        return this.joins;
      };

      Naub.prototype.partners = function() {
        var x, _i, _len, _ref, _results;
        _ref = this.joins;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          x = _ref[_i];
          _results.push(x);
        }
        return _results;
      };

      Naub.prototype.distance_to = function(other) {
        var diff, force, l, oforce, opos, ovel, pos, vel, _ref, _ref2;
        if (other.number !== this.number) {
          _ref = this.physics, pos = _ref.pos, vel = _ref.vel, force = _ref.force;
          _ref2 = other.physics, opos = _ref2.pos, ovel = _ref2.vel, oforce = _ref2.force;
          diff = opos.Copy();
          diff.Subtract(pos);
          return l = diff.Length();
        } else {
          return NaN;
        }
      };

      Naub.prototype.onclick = function() {};

      Naub.prototype.onfocus = function() {};

      Naub.prototype.focus = function() {
        this.focused = true;
        this.update();
        this.onfocus();
        return this.layer.naub_focused.dispatch(this);
      };

      Naub.prototype.unfocus = function() {
        this.focused = false;
        this.update();
        this.onclick();
        return this.layer.naub_unfocused.dispatch(this);
      };

      Naub.prototype.isHit = function(x, y) {
        var click, s;
        s = Naubino.settings.canvas.scale;
        click = new b2Vec2(x, y);
        click.Subtract(this.physics.pos);
        return (click.Length() < this.size) && !this.removed && !this.disabled;
      };

      Naub.prototype.color_to_rgba = function(color, shift) {
        var a, b, g, r;
        if (shift == null) shift = 0;
        r = Math.round(color[0] + shift);
        g = Math.round(color[1] + shift);
        b = Math.round(color[2] + shift);
        a = color[3];
        return "rgba(" + r + "," + g + "," + b + "," + a + ")";
      };

      Naub.prototype.random_palette_color = function() {
        var id, palette;
        palette = Naubino.colors;
        return id = Math.round(Math.random() * (palette.length - 1));
      };

      return Naub;

    })();
  });

}).call(this);
