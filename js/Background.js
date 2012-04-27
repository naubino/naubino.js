(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(["Layer"], function(Layer) {
    var Background;
    return Background = (function(_super) {

      __extends(Background, _super);

      function Background(canvas) {
        Background.__super__.constructor.call(this, canvas);
        this.name = "background";
        this.animation.name = "background.animation";
        this.drawing = true;
        this.default_thickness = this.basket_thickness = 4;
        this.ttl = 12;
        this.color = [0, 0, 0, 0.5];
        this.pulsating = false;
        this.seed = 0;
      }

      Background.prototype.draw = function() {
        return this.draw_basket();
      };

      Background.prototype.step = function(dt) {
        if (this.pulsating) return this.pulse();
      };

      Background.prototype.draw_basket = function() {
        var centerX, centerY, height, width;
        width = this.canvas.width;
        height = this.canvas.height;
        centerX = width / 2;
        centerY = height / 2;
        this.basket_size = Naubino.game.basket_size || 10;
        this.ctx.clearRect(0, 0, width, height);
        this.ctx.save();
        this.ctx.beginPath();
        this.ctx.arc(centerX, centerY, this.basket_size + this.basket_thickness / 2, 0, Math.PI * 2, false);
        this.ctx.lineWidth = this.basket_thickness;
        this.ctx.strokeStyle = this.color_to_rgba(this.color);
        this.ctx.stroke();
        this.ctx.closePath();
        return this.ctx.restore();
      };

      Background.prototype.start_pulse = function() {
        if (this.animation.current !== "playing") this.animation.play();
        return this.pulsating = true;
      };

      Background.prototype.stop_pulse = function() {
        return this.pulse_ends = true;
      };

      Background.prototype.pulse = function() {
        var rot;
        if (this.pulse_ends && Math.abs(this.default_thickness - this.basket_thickness) < 1) {
          this.pulsating = false;
          this.pulse_ends = false;
          this.basket_thickness = this.default_thickness;
          this.color[0] = 0;
          this.color[3] = 0.5;
          this.animation.pause();
        }
        this.basket_thickness = Math.abs(Math.sin(this.seed / this.ttl)) * 2 * this.default_thickness + this.default_thickness;
        rot = Math.sin(this.seed / this.ttl);
        this.color[0] = Math.abs(rot) * 200;
        this.color[3] = Math.abs(rot) * 0.5 + 0.5;
        return this.seed++;
      };

      Background.prototype.drawTextAlongArc = function(str, rot) {
        var angle, char, _i, _len;
        if (rot == null) rot = 0;
        angle = str.length * 0.1;
        this.ctx.save();
        this.ctx.translate(this.center.x, this.center.y);
        this.ctx.rotate(-1 * angle / 2);
        this.ctx.rotate(-1 * (angle / str.length) / 2 + rot);
        for (_i = 0, _len = str.length; _i < _len; _i++) {
          char = str[_i];
          this.ctx.rotate(angle / str.length);
          this.ctx.save();
          this.ctx.translate(0, -1 * this.basket_size + 15);
          this.ctx.fillStyle = this.color_to_rgba(this.color);
          this.ctx.textAlign = 'center';
          this.ctx.font = "" + 20 + "px Helvetica";
          this.ctx.fillText(char, 0, 0);
          this.ctx.restore();
        }
        return this.ctx.restore();
      };

      Background.prototype.draw_marker = function(x, y, color) {
        if (color == null) color = 'black';
        this.ctx.beginPath();
        this.ctx.arc(x, y, 4, 0, 2 * Math.PI, false);
        this.ctx.arc(x, y, 1, 0, 2 * Math.PI, false);
        this.ctx.lineWidth = 1;
        this.ctx.strokeStyle = color;
        this.ctx.stroke();
        return this.ctx.closePath();
      };

      Background.prototype.draw_line = function(x0, y0, x1, y1, color) {
        if (x1 == null) x1 = this.center.x;
        if (y1 == null) y1 = this.center.y;
        if (color == null) color = 'black';
        this.ctx.beginPath();
        this.ctx.moveTo(x0, y0);
        this.ctx.lineTo(x1, y1);
        this.ctx.lineWidth = 2;
        this.ctx.strokeStyle = color;
        this.ctx.stroke();
        return this.ctx.closePath();
      };

      return Background;

    })(Layer);
  });

}).call(this);
