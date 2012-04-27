(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(["Menu", "Layer", "Naub", "Graph", "Shapes"], function(Menu, Layer, Naub, Graph, _arg) {
    var Ball, MainButton, PauseButton, PlayButton, StringShape;
    Ball = _arg.Ball, StringShape = _arg.StringShape, PlayButton = _arg.PlayButton, PauseButton = _arg.PauseButton, MainButton = _arg.MainButton;
    return Menu = (function(_super) {

      __extends(Menu, _super);

      function Menu(canvas) {
        Menu.__super__.constructor.call(this, canvas);
        this.name = "menu";
        this.graph = new Graph(this);
        this.animation.name = "menu.animation";
        this.objects = {};
        this.hovering = false;
        this.drawing = true;
        this.gravity = Naubino.settings.physics.gravity.menu;
        this.listener_size = this.default_listener_size = 45;
        Naubino.mousemove.add(this.move_pointer);
        Naubino.mousedown.add(this.click);
        Naubino.menu_button.active = false;
        this.physics_fps = 35;
        this.position = new b2Vec2(20, 25);
        this.cube_size = 45;
        StateMachine.create({
          target: this,
          events: Naubino.settings.events,
          error: function(e, from, to, args, code, msg) {
            return console.error("" + this.name + "." + e + ": " + from + " -> " + to + "\n" + code + "::" + msg);
          }
        });
        /* definition of each button
        TODO: position should be dynamic
        */
      }

      Menu.prototype.oninit = function() {
        this.add_buttons();
        return this.start_stepper();
      };

      Menu.prototype.buttons = {
        main: {
          position: new b2Vec2(20, 25),
          shapes: [new MainButton]
        },
        play: {
          "function": function() {
            return Naubino.play();
          },
          position: new b2Vec2(65, 35),
          shapes: [new Ball, new PlayButton]
        },
        help: {
          "function": function() {
            return Naubino.tutorial();
          },
          position: new b2Vec2(45, 65),
          shapes: [new Ball, new StringShape("?", "white")]
        },
        exit: {
          "function": function() {
            return Naubino.stop();
          },
          position: new b2Vec2(14, 80),
          shapes: [new Ball, new StringShape("X", "white")]
        }
      };

      Menu.prototype.add_buttons = function() {
        var button, name, shape, _i, _len, _ref, _ref2;
        _ref = this.buttons;
        for (name in _ref) {
          button = _ref[name];
          this.objects[name] = new Naub(this);
          _ref2 = button.shapes;
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            shape = _ref2[_i];
            this.objects[name].add_shape(shape);
          }
          this.objects[name].update();
          this.objects[name].focus = button["function"];
          this.objects[name].disabled = button.disabled;
          this.objects[name].isClickable = false;
          this.objects[name].physics.pos.Set(button.position.x, button.position.y);
          this.objects[name].physics.mass = Naubino.settings.naub.mass_menu;
          this.objects[name].physics.attracted_to.Set(button.position.x, button.position.y);
          this.graph.remove_join(this.objects[name].join_with(this.objects.main, name));
        }
        return this.objects.main.life_rendering = true;
      };

      Menu.prototype.onenterplaying = function() {
        this.objects.play.focus = function() {
          return Naubino.pause();
        };
        this.objects.play.shapes.pop();
        this.objects.play.add_shape(new PauseButton);
        return this.objects.play.update();
      };

      Menu.prototype.onenterpaused = function() {
        this.objects.play.focus = function() {
          return Naubino.play();
        };
        this.objects.play.shapes.pop();
        this.objects.play.add_shape(new PlayButton);
        return this.objects.play.update();
      };

      Menu.prototype.onenterstopped = function(e, f, t) {
        if (e !== 'init') return this.onenterpaused();
      };

      Menu.prototype.step = function(dt) {
        var name, naub, _ref, _results;
        _ref = this.objects;
        _results = [];
        for (name in _ref) {
          naub = _ref[name];
          naub.step(dt);
          if (this.hovering) {
            _results.push(naub.physics.gravitate(dt));
          } else {
            _results.push(naub.physics.gravitate(dt, this.position));
          }
        }
        return _results;
      };

      Menu.prototype.update = function() {
        return this.objects.main.update();
      };

      Menu.prototype.move_pointer = function(x, y) {
        var _ref;
        return _ref = [x, y], this.pointer.x = _ref[0], this.pointer.y = _ref[1], _ref;
      };

      Menu.prototype.draw = function() {
        this.draw_menu();
        return this.draw_listener_region();
      };

      Menu.prototype.draw_menu = function() {
        var name, naub, _ref;
        this.ctx.clearRect(0, 0, Naubino.game_canvas.width, Naubino.game_canvas.height);
        this.ctx.save();
        _ref = this.objects;
        for (name in _ref) {
          naub = _ref[name];
          if (!naub.disabled) naub.draw_joins(this.ctx);
          if (!naub.disabled) naub.draw(this.ctx);
        }
        this.objects.main.draw(this.ctx);
        this.objects.main.draw_joins();
        this.draw_listener_region();
        return this.ctx.restore();
      };

      Menu.prototype.draw_listener_region = function() {
        this.ctx.save();
        this.ctx.beginPath();
        this.ctx.arc(0, 15, this.listener_size, 0, Math.PI * 2, true);
        if (this.ctx.isPointInPath(this.pointer.x, this.pointer.y)) {
          if (!this.hovering) {
            Naubino.menu_focus.dispatch();
            this.for_each(function(b) {
              return b.isClickable = true;
            });
            this.listener_size = 90;
            this.start_stepper();
          }
        } else if (this.hovering) {
          Naubino.menu_blur.dispatch();
          this.for_each(function(b) {
            return b.isClickable = false;
          });
          this.listener_size = this.default_listener_size;
          setTimeout(this.stop_stepper, 1000);
        }
        this.ctx.closePath();
        return this.ctx.restore();
      };

      return Menu;

    })(Layer);
  });

}).call(this);
