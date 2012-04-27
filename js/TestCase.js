(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(["Naub", "Game", "Shapes", "StandardGame"], function(Naub, Game, _arg, StandardGame) {
    var Ball, FrameCircle, NumberShape, TestCase;
    NumberShape = _arg.NumberShape, Ball = _arg.Ball, FrameCircle = _arg.FrameCircle;
    return TestCase = (function(_super) {

      __extends(TestCase, _super);

      function TestCase() {
        TestCase.__super__.constructor.apply(this, arguments);
      }

      TestCase.prototype.oninit = function() {
        var _this = this;
        this.create_matching_naubs();
        this.gravity = true;
        this.naub_replaced.add(function(number) {
          return _this.graph.cycle_test(number);
        });
        this.cycle_found.add(function(list) {
          return _this.destroy_naubs(list);
        });
        return Naubino.play();
      };

      TestCase.prototype.onplaying = function() {
        var weightless,
          _this = this;
        this.animation.play();
        this.start_stepper();
        Naubino.background.animation.play();
        Naubino.background.start_stepper();
        return weightless = function() {
          return _this.gravity = false;
        };
      };

      TestCase.prototype.event = function() {
        var inner_basket;
        inner_basket = this.count_basket();
        return this.destroy_naubs(inner_basket);
      };

      TestCase.prototype.create_naub_pair = function(x, y, color_a, color_b) {
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
        naub_a.add_shape(new FrameCircle);
        naub_b.add_shape(new Ball);
        naub_b.add_shape(new FrameCircle);
        color_a = naub_a.color_id;
        color_b = naub_b.color_id;
        this.add_object(naub_a);
        this.add_object(naub_b);
        naub_a.add_shape(new NumberShape);
        naub_b.add_shape(new NumberShape);
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

      return TestCase;

    })(StandardGame);
  });

}).call(this);
