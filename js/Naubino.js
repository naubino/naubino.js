(function() {

  define(["Background", "Game", "Keybindings", "Menu", "Overlay", "StandardGame", "TestCase", "Settings", "Tutorial"], function(Background, Game, KeyBindings, Menu, Overlay, StandardGame, TestCase, Settings, Tutorial) {
    var Naubino;
    return Naubino = (function() {

      function Naubino() {
        console.log("Naubino Constructor");
        this.name = "Naubino";
        this.settings = Settings;
        this.colors = this.settings.colors.output;
        this.create_fsm();
        this.Signal = window.signals.Signal;
        this.add_signals();
        this.add_listeners();
      }

      Naubino.prototype.setup = function() {
        this.init_dom();
        this.init_layers();
        this.setup_keybindings();
        this.setup_cursorbindings();
        return console.timeEnd("loading");
      };

      Naubino.prototype.print = function() {
        return this.gamediv.insertAdjacentHTML("afterend", "<img src=\"" + (this.game_canvas.toDataURL()) + "\"/>");
      };

      Naubino.prototype.init_dom = function() {
        var canvas, _i, _len, _ref, _results;
        this.gamediv = document.querySelector("#gamediv");
        this.overlay_canvas = document.querySelector("#overlay_canvas");
        this.menu_canvas = document.querySelector("#menu_canvas");
        this.game_canvas = document.querySelector("#game_canvas");
        this.background_canvas = document.querySelector("#background_canvas");
        _ref = this.gamediv.querySelectorAll("canvas");
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          canvas = _ref[_i];
          canvas.width = this.settings.canvas.width;
          _results.push(canvas.height = this.settings.canvas.height);
        }
        return _results;
      };

      Naubino.prototype.init_layers = function() {
        var width;
        this.gamediv.max - (width = this.settings.canvas.width);
        this.background = new Background(this.background_canvas);
        this.game_standard = new StandardGame(this.game_canvas);
        this.game_testcase = new TestCase(this.game_canvas);
        this.game = this.game_standard;
        this.menu = new Menu(this.menu_canvas);
        this.overlay = new Overlay(this.overlay_canvas);
        this.menu.init();
        this.menu.animation.play();
        return this.game.init();
      };

      /*
        Everything has to have state
      */

      Naubino.prototype.create_fsm = function() {
        return StateMachine.create({
          target: this,
          initial: {
            state: 'stopped',
            event: 'init'
          },
          events: this.settings.events,
          error: function(e, from, to, args, code, msg) {
            return console.error("" + this.name + "." + e + ": " + from + " -> " + to + "\n" + code + "::" + msg);
          }
        });
      };

      Naubino.prototype.list_states = function() {
        var o, _i, _len, _ref, _results;
        this.name = "Naubino";
        _ref = [this, this.menu, this.game, this.overlay.animation, this.menu.animation, this.game.animation, this.background.animation];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          o = _ref[_i];
          switch (o.current) {
            case 'playing':
              _results.push(console.info(o.name, o.current));
              break;
            case 'paused':
              _results.push(console.warn(o.name, o.current));
              break;
            case 'stopped':
              _results.push(console.warn(o.name, o.current));
              break;
            default:
              _results.push(console.error(o.name, o.current));
          }
        }
        return _results;
      };

      Naubino.prototype.onchangestate = function(e, f, t) {
        return console.info("Naubino changed states " + e + ": " + f + " -> " + t);
      };

      Naubino.prototype.onbeforeplay = function(event, from, to) {
        return this.game.play();
      };

      Naubino.prototype.onenterplaying = function() {
        return this.menu.play();
      };

      Naubino.prototype.toggle = function() {
        switch (this.current) {
          case 'playing':
            return this.pause();
          case 'paused':
            return this.play();
          case 'stopped':
            return this.play();
        }
      };

      Naubino.prototype.onbeforepause = function(event, from, to) {
        if (from !== "init") {
          this.game.pause();
          return this.menu.pause();
        }
      };

      Naubino.prototype.onenterpaused = function() {};

      Naubino.prototype.onpause = function(event, from, to) {};

      Naubino.prototype.onbeforestop = function(event, from, to, override) {
        this.override = override != null ? override : false;
        this.game.stop();
        if (this.game.current === "stopped") {
          return this.menu.stop();
        } else {
          return false;
        }
      };

      Naubino.prototype.tutorial = function() {
        this.game_tutorial = new Tutorial(this.game_canvas);
        return this.soft_switch(this.game_tutorial);
      };

      Naubino.prototype.soft_switch = function(new_game) {
        var _this = this;
        if (this.current === "playing") this.pause();
        return this.game.fade_out(function() {
          _this.game.clear();
          _this.game = new_game;
          _this.game.draw();
          if (_this.game.current === "none") _this.game.init();
          return _this.game.fade_in(function() {
            return _this.play();
          });
        });
      };

      Naubino.prototype.scale = function(nscale) {
        var canvas, oscale, ratio, _i, _len, _ref, _results;
        console.log(oscale = 1);
        this.settings.canvas.scale = nscale;
        console.log(ratio = nscale / oscale);
        _ref = this.gamediv.querySelectorAll("canvas");
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          canvas = _ref[_i];
          _results.push(canvas.getContext('2d').scale(ratio, ratio));
        }
        return _results;
      };

      /*
        Signals connect everything else that does not react to events
      */

      Naubino.prototype.add_signals = function() {
        this.mousedown = new this.Signal();
        this.mouseup = new this.Signal();
        this.mousemove = new this.Signal();
        this.keydown = new this.Signal();
        this.keyup = new this.Signal();
        this.touchstart = new this.Signal();
        this.touchend = new this.Signal();
        this.touchmove = new this.Signal();
        this.menu_button = new this.Signal();
        this.menu_focus = new this.Signal();
        return this.menu_blur = new this.Signal();
      };

      Naubino.prototype.add_listeners = function() {
        var _this = this;
        this.menu_focus.add(function() {
          return _this.menu.hovering = _this.menu_button.active = true;
        });
        return this.menu_blur.add(function() {
          return _this.menu.hovering = _this.menu_button.active = false;
        });
      };

      Naubino.prototype.setup_keybindings = function() {
        var _this = this;
        this.keybindings = new KeyBindings();
        window.onkeydown = function(key) {
          return _this.keybindings.keydown(key);
        };
        window.onkeyup = function(key) {
          return _this.keybindings.keyup(key);
        };
        return this.keybindings.enable(32, function() {
          return _this.toggle();
        });
      };

      Naubino.prototype.setup_cursorbindings = function() {
        var onmousedown, onmousemove, onmouseup,
          _this = this;
        onmousemove = function(e) {
          var x, y;
          x = (e.pageX - _this.overlay_canvas.offsetLeft) / _this.settings.canvas.scale;
          y = (e.pageY - _this.overlay_canvas.offsetTop) / _this.settings.canvas.scale;
          return _this.mousemove.dispatch(x, y);
        };
        onmouseup = function(e) {
          var x, y;
          x = (e.pageX - _this.overlay_canvas.offsetLeft) / _this.settings.canvas.scale;
          y = (e.pageY - _this.overlay_canvas.offsetTop) / _this.settings.canvas.scale;
          return _this.mouseup.dispatch(x, y);
        };
        onmousedown = function(e) {
          var x, y;
          x = (e.pageX - _this.overlay_canvas.offsetLeft) / _this.settings.canvas.scale;
          y = (e.pageY - _this.overlay_canvas.offsetTop) / _this.settings.canvas.scale;
          return _this.mousedown.dispatch(x, y);
        };
        this.overlay_canvas.addEventListener("mousedown", onmousedown, false);
        this.overlay_canvas.addEventListener("mouseup", onmouseup, false);
        this.overlay_canvas.addEventListener("mousemove", onmousemove, false);
        this.overlay_canvas.addEventListener("mouseout", onmouseup, false);
        this.overlay_canvas.addEventListener("touchstart", onmousedown, false);
        this.overlay_canvas.addEventListener("touchend", onmouseup, false);
        return this.overlay_canvas.addEventListener("touchmove", onmousemove, false);
      };

      return Naubino;

    })();
  });

}).call(this);
