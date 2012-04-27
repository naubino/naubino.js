(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(["Game"], function(Game) {
    var StandardGame;
    return StandardGame = (function(_super) {

      __extends(StandardGame, _super);

      function StandardGame(canvas) {
        this.event = __bind(this.event, this);
        this.check = __bind(this.check, this);        StandardGame.__super__.constructor.call(this, canvas);
      }

      /* state machine
      */

      StandardGame.prototype.oninit = function() {
        var _this = this;
        this.inner_clock = 0;
        this.points = 0;
        Naubino.background.basket_size = this.basket_size;
        this.naub_replaced.add(function(number) {
          return _this.graph.cycle_test(number);
        });
        this.naub_destroyed.add(function() {
          return _this.points++;
        });
        this.cycle_found.add(function(list) {
          return _this.destroy_naubs(list);
        });
        this.basket_size = this.default_basket_size = 160;
        this.spammers = this.default_spammers = {
          pair: {
            method: function() {
              return _this.create_naub_pair(null, null, _this.max_color(), _this.max_color());
            },
            probability: 5
          },
          triple: {
            method: function() {
              return _this.create_naub_triple(null, null, _this.max_color(), _this.max_color(), _this.max_color());
            },
            probability: 0
          }
        };
        this.levels = {
          game: this
        };
        return StateMachine.create({
          target: this.levels,
          initial: 'level1',
          error: function(e, f, t, a, ec, em) {
            if (e !== 'click') return console.warn(e, f, t, a, ec, em);
          },
          events: [
            {
              name: 'reset',
              from: '*',
              to: 'level1'
            }, {
              name: 'levelUp',
              from: 'level1',
              to: 'level2'
            }, {
              name: 'levelUp',
              from: 'level2',
              to: 'level3'
            }, {
              name: 'levelUp',
              from: 'level3',
              to: 'level4'
            }, {
              name: 'levelUp',
              from: 'level4',
              to: 'level5'
            }, {
              name: 'levelUp',
              from: 'level5',
              to: 'level6'
            }, {
              name: 'levelUp',
              from: 'level6',
              to: 'level7'
            }, {
              name: 'levelUp',
              from: 'level7',
              to: 'level8'
            }, {
              name: 'levelUp',
              from: 'level8',
              to: 'level9'
            }
          ],
          callbacks: {
            onchangestate: function() {
              if (this.current !== "level1") {
                Naubino.overlay.animation.play();
                return Naubino.overlay.fade_in_and_out_message(this.current, (function() {
                  return Naubino.overlay.animation.stop();
                }), 35);
              }
            },
            onlevel1: function() {
              console.log(this.current);
              this.game.spammers = this.game.default_spammers;
              this.game.basket_size = this.game.default_basket_size;
              this.game.number_of_colors = 3;
              this.game.spammer_interval = 40;
              return this.game.level_up_limit = 20;
            },
            onlevel2: function() {
              this.game.number_of_colors = 4;
              this.game.spammer_interval = 35;
              return this.game.level_up_limit = 45;
            },
            onlevel3: function() {
              this.game.number_of_colors = 5;
              this.game.spammer_interval = 30;
              return this.game.level_up_limit = 65;
            },
            onlevel4: function() {
              this.game.number_of_colors = 6;
              this.game.spammer_interval = 25;
              return this.game.level_up_limit = 90;
            },
            onlevel5: function() {
              this.game.spammers.triple.probability = 1;
              return this.game.level_up_limit = 120;
            },
            onlevel6: function() {
              this.game.number_of_colors = Naubino.colors.length;
              return this.game.level_up_limit = 140;
            },
            onlevel7: function() {
              this.game.spammer_interval = 20;
              return this.game.level_up_limit = 165;
            },
            onlevel8: function() {
              this.game.spammers.triple.probability = 2;
              this.game.basket_size = 140;
              return this.game.level_up_limit = 200;
            },
            onlevel9: function() {
              Naubino.overlay.animation.play();
              Naubino.overlay.fade_in_and_out_message("you got further than we implemented", Naubino.stop(true));
              return this.game.level_up_limit = 250;
            }
          }
        });
      };

      StandardGame.prototype.max_color = function() {
        return Math.floor(Math.random() * this.number_of_colors);
      };

      StandardGame.prototype.map_spammers = function() {
        var name, spammer, sum, _ref, _results;
        sum = 0;
        _ref = this.spammers;
        _results = [];
        for (name in _ref) {
          spammer = _ref[name];
          sum += spammer.probability;
          _results.push({
            range: sum,
            name: name,
            method: spammer.method
          });
        }
        return _results;
      };

      StandardGame.prototype.spam = function() {
        var dart, max, min, name, probabilites, spam, spammer, _i, _len, _ref;
        probabilites = (function() {
          var _ref, _results;
          _ref = this.spammers;
          _results = [];
          for (name in _ref) {
            spam = _ref[name];
            _results.push(spam.probability);
          }
          return _results;
        }).call(this);
        max = probabilites.reduce(function(f, s) {
          return f + s;
        });
        min = 0;
        dart = Math.floor(Math.random() * (max - min)) + min;
        _ref = this.map_spammers();
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          spammer = _ref[_i];
          if (dart < spammer.range) {
            console.log(spammer.name);
            spammer.method();
            return;
          }
        }
      };

      StandardGame.prototype.onchangestate = function(e, f, t) {};

      StandardGame.prototype.onbeforeplay = function() {};

      StandardGame.prototype.onplaying = function() {
        StandardGame.__super__.onplaying.call(this);
        Naubino.background.animation.play();
        Naubino.background.start_stepper();
        this.spamming = setInterval(this.event, 100);
        return this.checking = setInterval(this.check, 300);
      };

      StandardGame.prototype.onleaveplaying = function() {
        StandardGame.__super__.onleaveplaying.call(this);
        clearInterval(this.spamming);
        return clearInterval(this.checking);
      };

      StandardGame.prototype.onpaused = function() {
        StandardGame.__super__.onpaused.call(this);
        Naubino.background.animation.pause();
        return Naubino.background.stop_stepper();
      };

      StandardGame.prototype.onbeforestop = function(e, f, t) {
        if (Naubino.override) {
          console.log("killed");
          return true;
        } else {
          return confirm("do you realy want to stop the game?");
        }
      };

      StandardGame.prototype.onstopped = function(e, f, t) {
        if (e !== 'init') {
          Naubino.background.animation.stop();
          Naubino.background.stop_stepper();
          this.animation.stop();
          this.levels.reset();
          this.stop_stepper();
          this.clear();
          this.clear_objects();
          this.points = 0;
        } else {
          console.info("game initialized");
        }
        return true;
      };

      StandardGame.prototype.check = function() {
        var capacity, critical_capacity;
        capacity = this.capacity();
        critical_capacity = 35;
        if (this.capacity() < critical_capacity) {
          if (Naubino.background.pulsating === false) {
            Naubino.background.start_pulse();
          }
          Naubino.background.ttl = Math.floor(capacity / 2);
        } else if (Naubino.background.pulsating === true) {
          Naubino.background.stop_pulse();
          Naubino.background.ttl = critical_capacity;
        }
        if (this.capacity() < 0) this.lost();
        if (this.points > this.level_up_limit) return this.levels.levelUp();
      };

      StandardGame.prototype.lost = function() {
        Naubino.pause();
        Naubino.overlay.animation.play();
        Naubino.overlay.warning("Naub Overflow", this.basket_size / 4);
        return console.error("you lost", this.levels.current);
      };

      StandardGame.prototype.event = function() {
        if (this.inner_clock === 0) this.spam();
        return this.inner_clock = (this.inner_clock + 1) % this.spammer_interval;
      };

      return StandardGame;

    })(Game);
  });

}).call(this);
