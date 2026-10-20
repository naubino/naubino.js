naubino.js is a little game build for the browser. It is intended to be played on multi touch platforms.



# First Setup:

  * `git clone https://github.com/hoodie/naubino.js` ( "thanks for pointing out the obvious!!" - your welcome)
  * `git submodule update --init`
  * `make lib` some libs need some preparation
  * use index.html during development

# Make
  * thanks to Hydroo we have a make file
  * `make` works like a charm
  * `make watch` starts coffee with -w 
  * `make loc` lines of code

# Documentation
  * `make doc` generates documentation
  * `make todo` shows a todo


# Play it
  [play naubino online]( http://hoodie.github.com/naubino.js )

# Game modes

The standard game is selected by default (`?mode=standard`, or no `mode` parameter). Use `?mode=debug` to open the numbered debug playground; it starts automatically. Unknown mode values safely fall back to standard.

In standard mode, a quick two-finger tap (under 400 ms) toggles play/pause. In debug mode, placing two fingers spawns a joined pair immediately and continues spawning pairs every 300 ms while exactly those two fingers remain held. Lifting a finger, adding another, cancelling the touch, pausing, or stopping ends the repeat. Debug runs are unranked. Space still toggles play/pause, and Escape still stops.

# Application events

Each application owns a `Naubino.events` hub of named signals:

- `input`: `pointer_start`, `pointer_move`, `pointer_end`, `two_finger_start`, `two_finger_end`, `two_finger_tap`.
- `commands`: `play`, `pause`, `stop`, `toggle` requests handled by `Session`.
- `game`: `outcome`, `overflow_warning`, `basket_changed` notifications.
- `session`: `state_changed` publishes the new state, allowing input to cancel active gestures.
- `menu`: `button`, `focus`, `blur` signals.

Pointer events carry logical `(x, y)` coordinates. `stop` accepts an optional force flag; `outcome` carries a reason. Modes subscribe once in `bind(game, events)` and return an unsubscribe function. Subscriptions survive game resets and are removed on disposal. Simulation-local events such as `cycle_found` remain on the game rather than the hub.

# Endorsements

hoodie [![endorse](http://api.coderwall.com/hoodie/endorsecount.png)](http://coderwall.com/hoodie) 

payload [![endorse](http://api.coderwall.com/payload/endorsecount.png)](http://coderwall.com/payload) 
