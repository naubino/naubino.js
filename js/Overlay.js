(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(["Layer"], function(Layer) {
    var Overlay;
    return Overlay = (function(_super) {

      __extends(Overlay, _super);

      function Overlay(canvas) {
        this.queue_messages = __bind(this.queue_messages, this);        Overlay.__super__.constructor.call(this, canvas);
        this.name = "overlay";
        this.animation.name = "overlay.animation";
        this.fps = 1000 / 15;
        this.drawing = true;
        this.fade_speed = 40;
      }

      Overlay.prototype.draw = function() {
        var buffer, id, _ref;
        this.ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height);
        this.ctx.save();
        _ref = this.objects;
        for (id in _ref) {
          buffer = _ref[id];
          if (buffer.alpha != null) this.ctx.globalAlpha = buffer.alpha;
          this.ctx.drawImage(buffer, 0, 0);
          this.ctx.globalAlpha = 1;
        }
        return this.ctx.restore();
      };

      Overlay.prototype.warning = function(text, font_size, x, y) {
        var color;
        if (font_size == null) font_size = 25;
        if (x == null) x = this.center.x;
        if (y == null) y = this.center.y;
        color = this.color_to_rgba(Naubino.colors[0]);
        return this.message(text, font_size, color, x, y);
      };

      Overlay.prototype.fade_in_warning = function(text, callback, font_size, x, y) {
        var color;
        if (callback == null) callback = null;
        if (font_size == null) font_size = 25;
        if (x == null) x = this.center.x;
        if (y == null) y = this.center.y;
        color = this.color_to_rgba(Naubino.colors[0]);
        return this.fade_in_message(text, callback, font_size, color, x, y);
      };

      Overlay.prototype.fade_in_message = function(text, callback, font_size, color, x, y, ctx) {
        var fade, mes, mes_id,
          _this = this;
        if (callback == null) callback = null;
        if (font_size == null) font_size = 15;
        if (color == null) color = 'black';
        if (x == null) x = this.center.x;
        if (y == null) y = this.center.y;
        if (ctx == null) ctx = this.ctx;
        mes_id = this.message(text, font_size, color, x, y, ctx);
        mes = this.get_object(mes_id);
        mes.alpha = 0.01;
        fade = function() {
          if ((mes.alpha *= 1.2) >= 1) {
            clearInterval(mes.fadeloop);
            mes.alpha = 1;
            if (callback != null) callback.call();
            return console.log('fade in:', text);
          }
        };
        clearInterval(mes.fadeloop);
        mes.fadeloop = setInterval(fade, this.fade_speed);
        return mes_id;
      };

      /* fading out a specific message by id
      */

      Overlay.prototype.fade_out_message = function(mes_id, callback) {
        var fade, mes,
          _this = this;
        if (callback == null) callback = null;
        mes = this.get_object(mes_id);
        fade = function() {
          if ((mes.alpha *= 0.8) <= 0.05) {
            clearInterval(mes.fadeloop);
            if (callback != null) callback.call();
            return _this.remove_obj(mes_id);
          }
        };
        clearInterval(mes.fadeloop);
        if (mes != null) return mes.fadeloop = setInterval(fade, this.fade_speed);
      };

      /* fading out all messages
      */

      Overlay.prototype.fade_out_messages = function(callback) {
        var id, message, _ref;
        if (callback == null) callback = null;
        _ref = this.objects;
        for (id in _ref) {
          message = _ref[id];
          this.fade_out_message(id);
        }
        if (callback != null) return callback();
      };

      Overlay.prototype.fade_in_and_out_message = function(text, callback, font_size, color, x, y, ctx) {
        var fade_out, mes, mes_id, time, _ref, _ref2, _ref3,
          _this = this;
        if (callback == null) callback = null;
        if (font_size == null) font_size = 15;
        if (color == null) color = 'black';
        if (x == null) x = this.center.x;
        if (y == null) y = this.center.y;
        if (ctx == null) ctx = this.ctx;
        if (Array.isArray(text)) {
          font_size = (_ref = text[2]) != null ? _ref : font_size;
          time = (_ref2 = text[1]) != null ? _ref2 : 1000;
          text = (_ref3 = text[0]) != null ? _ref3 : "";
        } else {
          time = 2000;
        }
        fade_out = function() {
          return setTimeout(function() {
            return _this.fade_out_message(mes_id, callback);
          }, time);
        };
        mes_id = this.fade_in_message(text, fade_out, font_size, color, x, y, ctx);
        return mes = this.get_object(mes_id);
      };

      Overlay.prototype.queue_messages = function(messages, callback, font_size) {
        var m,
          _this = this;
        if (messages == null) messages = ["hello", "world"];
        if (callback == null) callback = null;
        if (font_size == null) font_size = 15;
        if (m = messages.shift()) {
          messages = messages.slice(0);
          return this.fade_in_and_out_message(m, (function() {
            return _this.queue_messages(messages, callback, font_size);
          }), font_size);
        } else {
          if (callback != null) return callback();
        }
      };

      Overlay.prototype.message = function(text, font_size, color, x, y, ctx) {
        var buffer, line, lines, _i, _len;
        if (font_size == null) font_size = 15;
        if (color == null) color = 'black';
        if (x == null) x = this.center.x;
        if (y == null) y = this.center.y;
        if (ctx == null) ctx = this.ctx;
        buffer = document.createElement('canvas');
        buffer.width = Naubino.settings.canvas.width;
        buffer.height = Naubino.settings.canvas.height;
        buffer.alpha = 1;
        ctx = buffer.getContext('2d');
        lines = text.split("\n");
        y -= font_size * lines.length / 2;
        for (_i = 0, _len = lines.length; _i < _len; _i++) {
          line = lines[_i];
          this.render_text(line, font_size, color, x, y, ctx);
          y += font_size;
        }
        return this.add_object(buffer);
      };

      Overlay.prototype.render_text = function(text, font_size, color, x, y, ctx) {
        if (font_size == null) font_size = 15;
        if (color == null) color = 'black';
        if (x == null) x = this.center.x;
        if (y == null) y = this.center.y;
        if (ctx == null) ctx = this.ctx;
        ctx.fillStyle = color;
        ctx.shadowColor = '#fff';
        ctx.shadowBlur = 3;
        ctx.strokeStyle = color;
        ctx.textAlign = 'center';
        ctx.font = "" + font_size + "px Helvetica";
        return ctx.fillText(text, x, y);
      };

      return Overlay;

    })(Layer);
  });

}).call(this);
