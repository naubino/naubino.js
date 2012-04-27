(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  define(["Game"], function(Game) {
    var Tutorial;
    return Tutorial = (function(_super) {

      __extends(Tutorial, _super);

      Tutorial.name = "Tutorial";

      /*
        # Lesson 1
        #   Naubs can be moved
        #   Naubs can be joined
        # Lesson 2
        #   Cycles dissolve
        # vvvv TODO vvvv
        #   Single Naubs can be attached to any color TODO: modify create_matching_naubs accordingly
        # Lesson 3
        #   Naubs keep being generated
        #   Too many Naubs can kill you
      */

      function Tutorial(canvas, graph) {
        this.toggle_joining = __bind(this.toggle_joining, this);        Tutorial.__super__.constructor.call(this, canvas, graph);
      }

      Tutorial.prototype.configure = function() {
        var _this = this;
        Naubino.overlay.animation.play();
        this.font_size = 24;
        Naubino.menu_focus.active = false;
        Naubino.game.joining_allowed = false;
        return this.lessons = StateMachine.create({
          initial: 'welcome',
          error: function(e, f, t, a, ec, em) {
            if (e !== 'click') return console.warn(e, f, t, a, ec, em);
          },
          events: [
            {
              name: 'click',
              from: 'welcome',
              to: 'lesson_show'
            }, {
              name: 'shown',
              from: 'lesson_show',
              to: 'lesson_move'
            }, {
              name: 'moved',
              from: 'lesson_move',
              to: 'lesson_join'
            }, {
              name: 'joined',
              from: 'lesson_join',
              to: 'lesson_cycle'
            }, {
              name: 'click',
              from: 'lesson_cycle',
              to: 'success'
            }
          ],
          callbacks: {
            onchangestate: function(e, f, t) {
              return console.info("" + f + " --(" + e + ")--> " + t);
            },
            onwelcome: function(e, f, t) {
              Naubino.mousedown.active = false;
              Naubino.mousedown.add(function() {
                return _this.lessons.click();
              });
              Naubino.overlay.fade_in_message("Tutorial", null, _this.font_size);
              setTimeout(function() {
                Naubino.overlay.fade_in_message("\n\nclick to continue", null, 12);
                return Naubino.mousedown.active = true;
              }, 1000);
              return setTimeout(function() {
                return Naubino.overlay.fade_in_and_out_message(["use the menu to restart this tutorial at any time", 5000], null, 12, 'black', Naubino.settings.canvas.width / 2, Naubino.settings.canvas.height - 10);
              }, 3000);
            },
            onleavewelcome: function() {
              var _this = this;
              Naubino.overlay.fade_out_messages(function() {
                return _this.transition();
              });
              return false;
            },
            onclick: function() {},
            onlesson_show: function() {
              var messages, strings;
              setTimeout(function() {
                _this.create_naubs();
                Naubino.game.for_each(function(naub) {
                  return naub.disable();
                });
                return console.warn("naubs inserted");
              }, 4300);
              strings = [["Lesson 1", 1300, _this.font_size * 2], ["Naubino is all about Naubs", 1000], ["These are Naubs", 1000], ["They always come in pairs", 1000], ["Try to move them around!", 1000]];
              messages = function() {
                return Naubino.overlay.queue_messages(strings, (function() {
                  return _this.lessons.shown();
                }), _this.font_size);
              };
              return setTimeout(messages, 2000);
            },
            onlesson_move: function() {
              var binding1, binding2;
              Naubino.game.for_each(function(naub) {
                return naub.enable();
              });
              binding1 = _this.naub_focused.add(function(naub) {
                return naub.old_pos = naub.physics.pos.Copy();
              });
              binding2 = _this.naub_unfocused.add(function(naub) {
                var dragged_distance, new_pos;
                new_pos = naub.physics.pos.Copy();
                new_pos.Subtract(naub.old_pos);
                dragged_distance = new_pos.Length();
                if (dragged_distance > 180) {
                  binding1.detach();
                  binding2.detach();
                  return _this.lessons.moved();
                }
              });
              return _this.fallback_warning_timer = setTimeout((function() {
                return Naubino.overlay.fade_in_and_out_message(["Just drag one pair across.", 3000], null, _this.font_size);
              }), 10000);
            },
            onleavelesson_move: function() {
              clearTimeout(_this.fallback_warning_timer);
              Naubino.overlay.fade_out_messages(function() {
                return _this.transition();
              });
              return false;
            },
            onlesson_join: function() {
              Naubino.game.joining_allowed = false;
              _this.naub_replaced.addOnce(function() {
                Naubino.overlay.queue_messages([["nicely done!", 2000]], function() {
                  return _this.lessons.joined();
                }, _this.font_size);
                return _this.toggle_joining();
              });
              return Naubino.overlay.queue_messages([["very Good", 1000], ["Every Naub has a certain color", 1000], ["You can connect pairs of Naubs...", 1400], ["...by dragging on Naub onto\nanother with the same color", 3000], ["Now try to connect two pairs of naubs!", 3000]], _this.toggle_joining, _this.font_size);
            },
            onlesson_cycle: function(e, f, t) {
              Naubino.game.cycle_found.add(function() {
                return Naubino.overlay.queue_messages([["Great", 4000]], null, _this.font_size);
              });
              return Naubino.overlay.queue_messages([["now connect the remaining naubs", 2500], ["and see what happens...", 2000]], _this.toggle_joining, _this.font_size);
            },
            onsuccess: function() {
              return console.info;
            }
          }
        });
      };

      Tutorial.prototype.onplaying = function() {
        return this.configure();
      };

      /* utility
      */

      Tutorial.prototype.toggle_joining = function() {
        this.joining_allowed = !this.joining_allowed;
        return console.log("joining_allowed", this.joining_allowed);
      };

      Tutorial.prototype.create_naubs = function() {
        var weightless;
        Naubino.game.gravity = true;
        Naubino.game.create_matching_naubs(1);
        Naubino.game.start_timer();
        weightless = function() {
          return Naubino.game.gravity = false;
        };
        return setTimeout(weightless, 5500);
      };

      return Tutorial;

    })(Game);
  });

}).call(this);
