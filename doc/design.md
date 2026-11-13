# Design

Target architecture for Naubino. Replaces `architecture-plan.md` and
`signal-transition-plan.md`.

Each claim has an ID and a **Check** you can verify against the source.
Claims describe the target state. `Status` says whether the code already
matches. Implement stage by stage (see [Stages](#stages)). Never break a
claim marked `done`.

Rules for implementers:

- Read `src/AGENTS.md` first. Use Deno tasks. Never write or modify tests.
- One stage per change. Build and play after each stage.
- Don't invent new classes unless a claim names them.
- No single-letter variable names in new code.
- CoffeeScript returns its last expression implicitly. Use an explicit `return`
  for values computed inside branches.

---

## Vocabulary

| Term | Meaning |
|---|---|
| Shell | `Naubino`. Page lifetime. Builds and wires everything. |
| Game | One round of play, from ready until finished. Disposable. |
| Mode | Configuration data handed to a Game. |
| Rule | Behavior unit inside a Game (spawning, scoring, levels, ...). |
| Command | Signal that requests work. Exactly one handler. |
| Notification | Signal that reports something that already happened. Any number of subscribers. |

---

## Ownership

| ID | Claim | Check | Status |
|---|---|---|---|
| O1 | `Naubino` is the shell. It owns `Viewport`, `GameLoop`, `Input`, `Settings`, `Audio`, `Menu`, highscores, `AppEvents`, and a reference to the current `Game`. | These are constructed in `Naubino.coffee` and nowhere else. | partial |
| O2 | `Game` is disposable. One instance per round. Restart, stop, and mode switch all dispose the current `Game` and construct a new one. | No method resets a live `Game` (`configure_run`, `switch_mode` don't exist). | todo |
| O3 | `Session` does not exist. | `src/Session.coffee` is gone; `grep Session src` finds nothing. | todo |
| O4 | `Game` owns `World`, `Graph`, rules, `Factory`, `DragSystem`, `JoinPolicy`, `CollisionHandler`, `GameEvents`, and its layers. Nothing outside `Game` constructs them. | `grep "new World\|new Graph\|new CollisionHandler" src` only hits `Game` (and `Menu`'s private `Graph`). | partial |
| O5 | `Game` decides which layers it uses and owns them. It does not extend `Layer`. The shell registers the returned layers with `Viewport` and `GameLoop`. | `class Game` has no `extends Layer`; shell calls `viewport.set_layers` with `game.layers`. | todo |
| O6 | `Menu` belongs to the shell and survives games. | `Menu` is constructed in `Naubino`, never in `Game`. | done |
| O7 | `Mode` is data. It holds parameters (physics, spawner probabilities, level table, game config) and may name classes (for example a join policy). It runs no lifecycle code. | `Mode` has no `init`, `reset`, `playing`, `stop`, `dispose`, `bind`, `rules`. | todo |
| O8 | Behavior that differs in code, not numbers, is a `Game` subclass (`StandardGame`, `DebugGame`) or a pluggable rule. | `DebugMode`'s lifecycle hooks live in `DebugGame`. | todo |
| O9 | `active_tree` and `focused_naub` are `Game` interaction state. | Fields on `Game`, not `World`. | done |
| O10 | `World` performs join, split, and replace (final stage). `Naub` keeps visual and local state only. | `Naub` has no `@world.physics` access and no `@graph`. | todo |
| O11 | `Graph` takes no constructor arguments. | `constructor: ->` in `Graph.coffee`. | done |

## Events

| ID | Claim | Check | Status |
|---|---|---|---|
| E1 | Events use the existing `Signal` class with concrete named signals. No string event names, no new event library. | `grep "new Signal\|new Naubino.Signal" src` covers all event definitions. | done |
| E2 | `AppEvents` (page lifetime) holds `input`, `commands`, and settings/theme notifications. It holds nothing about score, level, basket, overflow, or outcome. | `src/Events.coffee` has no `game` namespace. | partial |
| E3 | `AppEvents` is constructed in `Naubino`'s constructor, not as a class-body property. | No `events: new Events()` at class level in `Naubino.coffee`. | done |
| E4 | Each `Game` owns one `GameEvents`. It contains internal simulation signals and outward notifications. Subclasses may add signals (`StandardGame` adds level and basket). | `World` and `Graph` declare no signals; naub and cycle signals live on `GameEvents`. | todo |
| E5 | Outward `GameEvents`: `state_changed(state)`, `score_changed(points)`, `level_changed(level)`, `chain_bonus(points)`, `overflow_warning(severity)`, `basket_changed(size)`, `lost(reason)`, `finished(snapshot)`, plus sound cues. | Signals exist with those payloads. | partial |
| E6 | `Game` subscribes to `AppEvents.input` and `AppEvents.commands` itself and unsubscribes on dispose. | Subscriptions collected in `Game` and released in `dispose`. | partial |
| E7 | UI never references `Game`, `Mode`, rules, or `World`. The shell's `attach(game)` is the only code that knows both sides. It returns a disposer. | `grep "game\\.\\|\\.mode\\." src/ui src/game/Shapes.coffee` finds no traversal; `MainButton` draws a cached value. | partial |
| E8 | Payloads carry the data consumers need. A new `Game` publishes its initial snapshot (score 0, level 0, basket size or none) after `attach`. | `basket_changed` has a payload; `set_basket_size_provider` is gone. | done |
| E9 | A command has one handler. A request is not proof of completion (`loss_requested` is not `lost`). Listener return values are never used. | Review. | todo |
| E10 | A multi-part mutation happens inside one owner. Only the committed result is published. Correctness never depends on subscriber order. | Review. | todo |
| E11 | `GameEvents` signals are deactivated on dispose. Late callbacks from a disposed game reach no subscriber. | `dispose` sets `active = false` on every `GameEvents` signal. | todo |
| E12 | Unused signals are removed: `menu.button`, `menu.focus`, `menu.blur`, `Game.game_draw`. Remove `naub_unfocused` unless a consumer appears. | `grep` finds no definitions. | todo |

## Lifecycle

| ID | Claim | Check | Status |
|---|---|---|---|
| L1 | `Game` FSM states: `ready`, `playing`, `paused`, `lost`, `finished`. `finished` is terminal and dispatches `finished(snapshot)` exactly once. | FSM config in `Settings.events.game`. | todo |
| L2 | On `finished` the shell stores the highscore, calls the `attach` disposer, disposes the `Game`, constructs the next one, and attaches it. | One shell method does all five steps in that order. | todo |
| L3 | `Game.dispose` stops rules, clears every interval and timeout it owns (spawner, check loop, destroy batches, `just_joined`, loss sequence), deactivates `GameEvents`, unsubscribes from `AppEvents`, and clears its canvases. Calls after dispose are no-ops. | `@disposed` guard on timer callbacks. | todo |
| L4 | A rule's constructor is its setup. `start`/`stop` mean play/pause. No `init` reset convention, no `start(from)`. | `Rule` has no `init`; `start` takes no argument. | todo |
| L5 | Object IDs start at 1 in every `Game`. | `World` has no `objects_count` constructor parameter. | todo |
| L6 | Stop confirmation happens in `Game` before entering `finished`. | `confirm_stop` called from `Game`'s FSM. | todo |
| L7 | The loss sequence (grey out, fade, wait, finish) lives in `Game`. `Overlay` shows the warning by reacting to `lost(reason)`. | No `Overlay` call inside `Game`. | todo |
| L8 | A new `Game` spawns its first naubs on construction, so the field is visible in `ready`. | Matches today's behavior. | done |
| L9 | Mode switch = finish without result + construct a `Game` with the new mode. | No `finished` snapshot is stored for a mode switch. | todo |

## Viewport

| ID | Claim | Check | Status |
|---|---|---|---|
| V1 | `Viewport` creates its canvases ordered by depth, distinguished by a CSS class rather than an `id`. | No `setAttribute 'id'` in `Viewport.coffee`; canvases carry a depth class. | todo |
| V2 | `viewport.lease()` hands out a layer a `Game` can draw into; `lease.release()` returns it. | `lease`/`release` exist on `Viewport`; `Game` calls them instead of constructing its own layer. | todo |
| V3 | `Game` does not extend `Layer`. It leases its field layer from `Viewport` instead. | No `extends Layer` on `class Game`. | todo |
| V4 | `Viewport` listens for Pointer Events on the container. The container has `touch-action: none`. | `pointerdown/move/up/cancel` listeners on `@container` in `Viewport.coffee`; `touch-action: none` in `naubino.css`. | done |
| V5 | Pointer routing is top-down over `@layers`, with a per-`pointerId` capture: the first layer that accepts a pointer keeps it until `pointer_end`/`pointer_cancel`. | `pointer_down` walks `@layers.slice().reverse()`; `@captures[pointer_id]` holds the chosen layer. | done |
| V6 | Hover (`pointer_move` with no active capture or gesture) is routed to `Menu` only for mouse pointers. | `pointer_move` checks `event.pointerType is 'mouse'` before forwarding to the menu layer. | done |
| V7 | A tap on the menu's region opens it even when the pointer is a touch pointer. | `Menu.accepts_pointer` and `Menu.pointer_start` are reached by `pointer_down` regardless of `pointerType`. | done |
| V8 | Two-finger gestures (pause toggle, drag cancel) are recognized and tracked in `Viewport`, not `Input`. | Gesture state (`@gesture`, `@active_pointers`) lives in `Viewport.coffee`; `Input.coffee` has none. | done |
| V9 | `Viewport` dispatches a `field_resized(width, height)` notification instead of calling a resize callback directly. | A `Signal` named `field_resized` on `Viewport` or `AppEvents`; no `@on_resize` callback property. | todo |
| V10 | `Game` takes its initial field size in the constructor and updates center, anchors, spawn bounds, and physics bounds from `field_resized`. | `Game`'s constructor signature includes a field size; `Game.resize` is the `field_resized` subscriber. | partial |
| V11 | `canvas.style` is only read or written inside `Viewport`. | `grep "canvas.style" src` has no hits outside `Viewport.coffee`. | todo |
| V12 | `Input` is keyboard-only. The `pointer_start`/`pointer_move`/`pointer_end` signals are removed from `Events`. | `Input.coffee` takes no `canvas`/`viewport`; `Events.input` has no `pointer_*` keys. | done |

## Joining and simulation

| ID | Claim | Check | Status |
|---|---|---|---|
| J1 | `Graph.add_join` returns a join ID. `Naub.join_with` uses it as the key for constraints, partner maps, and drawing state. | Verified fact. | done |
| J2 | Callers ignore the results of `Naub.join_with` and `Naub.replace_with`. | Verified fact. Don't add consumers. | done |
| J3 | `JoinPolicy.check_joining` returns `{action: 'join' \| 'replace', pair}` or `null`, never `false`. It does not mutate queues. `Game.check_joining` queues and returns a boolean. | Every return path in `JoinPolicy.coffee` is explicit. | done |
| J4 | Collision-triggered joins and replaces are queued and executed after the physics step. | `Game.step` drains queues after `physics.step`. | done |
| J5 | Factory joins (`create_naub_pair`, `create_naub_triple`) complete synchronously. | No queue used in `Factory`. | done |
| J6 | Structural join events (`join_added(id, first, second)`, `join_removed(id)`) fire for every join, including silent ones. Feedback (`naub_joined`) may be suppressed for silent joins. Graph syncs only from structural events. | `naub_joined` is never used to update `Graph`. | todo |
| J7 | Cycle evaluation runs only after a replacement has finished rewiring. | `naub_replaced` dispatched after all rewiring. | done |
| J8 | `naub_destroyed` means destruction *started*, not removal. | Dispatched in `Naub.destroy`, before the removal timeout. | done |
| J9 | Rule order is explicit: `[spawner, scoring, overflow, levels, graph_wiring]`. Levels writes into Spawner, Overflow checks before a level-up grows the basket. | Order in `StandardMode.rules` (later `StandardGame`). | done |

## Keep as direct calls

Do not turn these into signals:

- Queries: `Graph.tree`, `Graph.partners`, `World.get_object`, `World.naub_at`,
  `Naub.is_alone`, `is_joined_with`, `close_related`, `Basket.capacity`,
  `basket_size`, result snapshots.
- Factory calls whose return value gets customized right away (`DebugMode.add_ball`).
- Construction and ordered rule hooks (`start`, `stop`, `check`).
- Loss sequence steps, viewport resize, scale, and redraw, frame advance, physics step.
- Rendering, shapes, styles, animation helpers.
- `Settings.set` / `Settings.toggle` (already the single mutation API).
- Fullscreen request and result, highscore prompt and storage.

---

## Stages

Each stage builds and plays on its own. Mark claims `done` as they land.

### Stage 1: GameEvents and attach

Claims: E2, E3, E5 (except `finished`, `lost`), E7, E8.

1. Add `GameEvents` in `src/Events.coffee`. Construct it in `Game`.
2. Move `outcome`, `level_up` (rename `level_changed`), `chain_bonus`,
   `overflow_warning`, `basket_changed` off `Events.game` onto `GameEvents`.
   Update producers in `Levels`, `Scoring`, `Overflow`, `Game`.
3. `Scoring` dispatches `score_changed(points)` whenever points change.
4. `basket_changed(size)` carries `basket.basket_size()`.
5. Add `Naubino.attach(game)`. It wires `Menu` (score), `Overlay` (level,
   bonus), `Background` (basket, overflow). Returns a disposer.
6. `MainButton` draws a value cached on `Menu`. Remove `set_basket_size_provider`.
7. Construct `Events` inside `Naubino`'s constructor.

Exit check: `grep "game\.mode" src/ui src/game/Shapes.coffee src/Naubino.coffee` is empty.

### Stage 2: Disposable Game, Session retired

Claims: O2, O3, E6, L1, L2, L3, L6, L7, L9, E5 (`lost`, `finished`), E11.

1. Move command handling (`play`, `pause`, `stop`, `toggle`) from `Session` into `Game`.
2. Move stop confirmation and the loss sequence into `Game`.
3. `Game` dispatches `state_changed`, `lost`, `finished(snapshot)`.
4. Shell reacts: `Overlay`/`Background` play/pause/stop on `state_changed`,
   `Menu` play/pause button on `state_changed`, `Overlay.warning` on `lost`,
   highscore on `finished`.
5. Shell method `start_game(mode)` disposes the old game and builds the new
   one (L2). Use it for startup, finish, and mode switch.
6. Implement `Game.dispose` per L3. Audio subscribes through `attach`;
   remove `connect_to_game` calls from `Game`.
7. Delete `Session.coffee` and the `on_finished`, `check_game_state` plumbing.

Exit check: restart during destruction animations and mode switch while
playing, paused, ready all work in the browser.

### Stage 3: Delete reset machinery

Claims: L4, L5, E4, E12.

1. Remove `configure_run`, `switch_mode`, `Graph.clear`, `World.reset_signals`,
   the `previous_count` parameter.
2. Rule constructors do setup. Remove `Rule.init` and `start(from)`.
   `Scoring` sets `begin_time` on first `start`.
3. Move naub and cycle signals from `World`/`Graph` onto `GameEvents`.
   `Naub` dispatches through the game's events.
4. Remove unused signals (E12).

Exit check: `grep "configure_run\|switch_mode\|reset_signals\|init:" src/modes src/game` is empty.

### Stage 4: Game owns its layers

Claims: O5.

1. `Game` stops extending `Layer`. It constructs a field layer (and the
   layers it needs) from canvases the shell passes in.
2. Shell swaps `Viewport` and `GameLoop` layers in `start_game`.

### Stage 5: Game subclasses, Mode as data

Claims: O7, O8.

1. Add `StandardGame` and `DebugGame`. Move `StandardMode.rules` and
   `DebugMode`'s hooks into them.
2. `Mode` keeps only data and named classes.
3. `main.coffee` picks game class plus mode.

### Stage 6: Graph observes topology

Claims: J6.

1. Allocate join IDs outside `Graph` (in `Naub.join_with` for now).
2. Dispatch `join_added`/`join_removed`. `Graph` subscribes.
3. Remove `Naub.graph`.

### Stage 7: World owns joins

Claims: O10.

1. Move `join_with`, `split_join`, `replace_with` logic into `World`.
2. `Game.step` and `Factory` call `World`. `Naub` loses physics access.

### Backlog

- Fold `DragSystem` into `Game` (not scheduled).
- Theme and effects notifications on `AppEvents` (`theme_changed`,
  `effects_changed`), replacing scattered recolor and rate refresh calls.
- `CollisionHandler` dispatching `collision_observed` instead of calling `Game`.
- Overflow dispatching `loss_requested` instead of calling `Game.loose`.

---

## Validation

Build, after every stage:

- `deno task check`
- `deno task build`
- `deno task lint` (14 overlong level-table rows in `StandardMode.coffee` are pre-existing)

Browser, after every stage:

- Join, replace, and rejected joins work.
- Silent factory pairs show up in `Graph` without a join sound.
- Cycles score, show chain bonus, and destroy in order.
- Pause and resume keep elapsed time. A new game starts at zero.
- Restart during destruction animations does not affect the new game.
- Mode switch while ready, playing, paused leaves no old timers or handlers.
- Switching to `DebugMode` clears score and basket display.
- `DebugMode` gestures never spawn into a disposed game.
- Audio does not double-play after restarts.
- Highscore stores the finished game's result.
- Stop confirmation cancel keeps playing.

## Open questions

1. Does `Overlay` belong to the shell or the `Game`? Shell if it ever shows
   messages between games.
2. One `GameEvents` object or separate internal and outward objects?
3. Typed outward signals or a single `presentation_changed(snapshot)`?
4. `Game` subclass per kind of game, or one `Game` with pluggable rules only?
