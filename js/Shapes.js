(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(function() {
    var Ball, Clock, Frame, FrameCircle, MainButton, NumberShape, PauseButton, PlayButton, Shape, Shapes, Square, StringShape;
    return Shapes = {
      Shape: Shape = (function() {

        function Shape() {
          this.color_to_rgba = __bind(this.color_to_rgba, this);          this.style = {
            fill: [0, 0, 0, 1]
          };
        }

        Shape.prototype.setup = function(naub) {
          this.naub = naub;
          this.pos = this.naub.pos;
          this.ctx = this.naub.ctx;
          return this.set_color_from_id(this.naub.color_id);
        };

        Shape.prototype.color_to_rgba = function(color, shift) {
          var a, b, g, r;
          if (color == null) color = this.style.fill;
          if (shift == null) shift = 0;
          r = Math.round(color[0] + shift);
          g = Math.round(color[1] + shift);
          b = Math.round(color[2] + shift);
          a = color[3];
          return "rgba(" + r + "," + g + "," + b + "," + a + ")";
        };

        Shape.prototype.draw_shadow = function(ctx) {
          if (Naubino.settings.graphics.draw_shadows) {
            ctx.shadowColor = "#333";
            ctx.shadowBlur = 3;
            ctx.shadowOffsetX = 1;
            return ctx.shadowOffsetY = 1;
          }
        };

        Shape.prototype.set_opacity = function(value) {
          return this.style.fill[3] = value;
        };

        Shape.prototype.set_color_from_id = function(id) {
          var palette, pick;
          palette = Naubino.colors;
          pick = palette[id];
          this.style.fill = [pick[0], pick[1], pick[2], 1];
          return id;
        };

        Shape.prototype.random_color = function() {
          var b, g, r;
          r = Math.random();
          g = Math.random();
          b = Math.random();
          this.style.fill = [r, g, b, 1];
          return -1;
        };

        Shape.prototype.destroy_animation = function(callback) {
          var shrink,
            _this = this;
          if (callback == null) callback = null;
          this.naub.life_rendering = true;
          shrink = function() {
            _this.naub.size *= 0.8;
            _this.naub.join_style.width *= 0.6;
            _this.naub.join_style.fill[3] *= 0.6;
            _this.style.fill[3] *= 0.6;
            if ((callback != null) && _this.naub.size <= 0.1) {
              clearInterval(_this.loop);
              return callback.call();
            }
          };
          return this.loop = setInterval(shrink, 50);
        };

        return Shape;

      })(),
      Square: Square = (function(_super) {

        __extends(Square, _super);

        function Square() {
          Square.__super__.constructor.call(this);
          this.rot = 0;
        }

        Square.prototype.area = function() {
          return this.width / 2 * this.width / 2;
        };

        Square.prototype.render = function(ctx, x, y) {
          ctx.save();
          this.width = this.naub.size * 2;
          this.rot = this.rot + 0.1;
          ctx.translate(x, y);
          ctx.rotate(this.rot);
          ctx.beginPath();
          ctx.rect(-this.width / 2, -this.width / 2, this.width, this.width);
          this.draw_shadow(ctx);
          ctx.fillStyle = this.color_to_rgba(this.style.fill);
          ctx.fill();
          ctx.closePath();
          return ctx.restore();
        };

        Square.prototype.isHit = function(x, y) {
          this.layer.ctx.beginPath();
          this.layer.ctx.rect(this.pos.x - this.width / 2, this.pos.y - this.width / 2, this.width, this.width);
          this.layer.ctx.closePath();
          return this.layer.ctx.isPointInPath(x, y);
        };

        return Square;

      })(Shape),
      Ball: Ball = (function(_super) {

        __extends(Ball, _super);

        function Ball() {
          Ball.__super__.constructor.apply(this, arguments);
        }

        Ball.prototype.area = function() {
          return Math.PI * (this.naub.size / 2) * (this.naub.size / 2);
        };

        Ball.prototype.render = function(ctx, x, y) {
          var gradient, offset, size;
          if (x == null) x = 42;
          if (y == null) y = x;
          ctx.save();
          size = this.naub.size;
          offset = 0;
          ctx.translate(x, y);
          ctx.beginPath();
          ctx.arc(offset, offset, size, 0, Math.PI * 2, false);
          ctx.closePath();
          if (this.naub.focused) {
            gradient = ctx.createRadialGradient(offset, offset, size / 3, offset, offset, size);
            gradient.addColorStop(0, this.color_to_rgba(this.style.fill, 80));
            gradient.addColorStop(1, this.color_to_rgba(this.style.fill, 50));
            ctx.fillStyle = gradient;
          } else {
            ctx.fillStyle = this.color_to_rgba(this.style.fill);
          }
          this.draw_shadow(ctx);
          ctx.fill();
          ctx.closePath();
          return ctx.restore();
        };

        return Ball;

      })(Shape),
      Clock: Clock = (function(_super) {

        __extends(Clock, _super);

        function Clock() {
          Clock.__super__.constructor.call(this);
          this.start = 0;
        }

        Clock.prototype.setup = function(naub) {
          this.naub = naub;
          Clock.__super__.setup.call(this, this.naub);
          return this.naub.clock_progress = 0;
        };

        Clock.prototype.render = function(ctx, x, y) {
          var end, offset, size;
          if (x == null) x = 42;
          if (y == null) y = x;
          ctx.save();
          size = this.naub.size - 5;
          end = this.naub.clock_progress * Math.PI / 100;
          offset = 0;
          ctx.translate(x, y);
          ctx.beginPath();
          ctx.arc(offset, offset, size, this.start, end, false);
          ctx.fillStyle = this.color_to_rgba([255, 255, 255, 0.5]);
          ctx.strokeStyle = ctx.fillStyle;
          ctx.lineWidth = size + 3;
          ctx.stroke();
          ctx.closePath();
          return ctx.restore();
        };

        return Clock;

      })(Shape),
      Frame: Frame = (function(_super) {

        __extends(Frame, _super);

        function Frame(margin) {
          this.margin = margin != null ? margin : null;
          Frame.__super__.constructor.call(this);
        }

        Frame.prototype.setup = function(naub) {
          this.naub = naub;
          Frame.__super__.setup.call(this, this.naub);
          if (this.margin != null) {
            return this.frame = this.margin + this.naub.size;
          } else {
            return this.frame = this.naub.frame + this.naub.size * 2;
          }
        };

        Frame.prototype.render = function(ctx, x, y) {
          if (x == null) x = 42;
          if (y == null) y = x;
          x = x - this.frame / 2;
          y = y - this.frame / 2;
          ctx.save();
          ctx.beginPath();
          ctx.moveTo(x, y);
          ctx.lineTo(x, this.frame + y);
          ctx.lineTo(this.frame + x, this.frame + y);
          ctx.lineTo(this.frame + x, y);
          ctx.lineTo(x, y);
          ctx.stroke();
          ctx.closePath();
          return ctx.restore();
        };

        return Frame;

      })(Shape),
      FrameCircle: FrameCircle = (function(_super) {

        __extends(FrameCircle, _super);

        function FrameCircle() {
          FrameCircle.__super__.constructor.apply(this, arguments);
        }

        FrameCircle.prototype.render = function(ctx, x, y) {
          var fill, r;
          if (x == null) x = 42;
          if (y == null) y = x;
          ctx.save();
          ctx.beginPath();
          r = this.naub.physics.margin * this.naub.size;
          ctx.arc(x, y, r, 0, Math.PI * 2, false);
          ctx.closePath();
          ctx.strokeStyle = "black";
          fill = this.style.fill;
          fill[3] = 0.3;
          ctx.fillStyle = this.color_to_rgba(fill);
          ctx.stroke();
          ctx.fill();
          ctx.closePath();
          return ctx.restore();
        };

        return FrameCircle;

      })(Frame),
      PlayButton: PlayButton = (function(_super) {

        __extends(PlayButton, _super);

        function PlayButton() {
          PlayButton.__super__.constructor.apply(this, arguments);
        }

        PlayButton.prototype.render = function(ctx, x, y) {
          ctx.save();
          ctx.beginPath();
          ctx.fillStyle = "#ffffff";
          ctx.moveTo(x - 5, y - 5);
          ctx.lineTo(x - 5, y + 5);
          ctx.lineTo(x + 7, y + 0);
          ctx.lineTo(x - 5, y - 5);
          ctx.closePath();
          ctx.fill();
          return ctx.restore();
        };

        return PlayButton;

      })(Shape),
      PauseButton: PauseButton = (function(_super) {

        __extends(PauseButton, _super);

        function PauseButton() {
          PauseButton.__super__.constructor.apply(this, arguments);
        }

        PauseButton.prototype.render = function(ctx, x, y) {
          ctx.save();
          ctx.fillStyle = "#ffffff";
          ctx.beginPath();
          ctx.rect(x - 5, y - 6, 4, 12);
          ctx.rect(x + 1, y - 6, 4, 12);
          ctx.closePath();
          ctx.fill();
          return ctx.restore();
        };

        return PauseButton;

      })(Shape),
      MainButton: MainButton = (function(_super) {

        __extends(MainButton, _super);

        function MainButton() {
          MainButton.__super__.constructor.apply(this, arguments);
        }

        MainButton.prototype.render = function(ctx, x, y) {
          var text, _ref;
          text = (_ref = Naubino.game.points) != null ? _ref : "";
          this.width = this.naub.size * 2.5;
          ctx.save();
          ctx.translate(x, y);
          ctx.rotate(Math.PI / 6);
          ctx.beginPath();
          ctx.rect(-this.width / 2, -this.width / 2, this.width, this.width);
          this.draw_shadow(ctx);
          ctx.fillStyle = this.color_to_rgba(this.style.fill);
          ctx.fill();
          ctx.closePath();
          ctx.restore();
          ctx.save();
          ctx.translate(x, y);
          ctx.fillStyle = 'white';
          ctx.textAlign = 'center';
          ctx.font = 'bold 33px Helvetica';
          ctx.fillText(text, 0, 10, this.width * 1.1);
          return ctx.restore();
        };

        return MainButton;

      })(Square),
      StringShape: StringShape = (function(_super) {

        __extends(StringShape, _super);

        function StringShape(string, color) {
          this.string = string;
          this.color = color != null ? color : "black";
          StringShape.__super__.constructor.call(this);
        }

        StringShape.prototype.setup = function(naub) {
          this.naub = naub;
          return StringShape.__super__.setup.call(this, this.naub);
        };

        StringShape.prototype.render = function(ctx, x, y) {
          var size;
          size = this.naub.size * 1.3;
          ctx.save();
          ctx.translate(x, y);
          ctx.fillStyle = this.color;
          ctx.textAlign = 'center';
          ctx.font = "" + size + "px Helvetica";
          ctx.fillText(this.string, 0, 6);
          return ctx.restore();
        };

        return StringShape;

      })(Shape),
      NumberShape: NumberShape = (function(_super) {

        __extends(NumberShape, _super);

        function NumberShape() {
          NumberShape.__super__.constructor.call(this, "", "white");
        }

        NumberShape.prototype.setup = function(naub) {
          this.naub = naub;
          NumberShape.__super__.setup.call(this, this.naub);
          return this.string = this.naub.number;
        };

        return NumberShape;

      })(StringShape)
    };
  });

}).call(this);
