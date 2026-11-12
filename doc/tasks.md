# Tasks

Progress tracker for [`design.md`](design.md). One section per commit.
Check items off as they land. Mark the claims in `design.md` as `done` too.

Before each commit: `deno task check`, `deno task build`, `deno task lint`.

## 0. Prep

- [ ] Commit or stash the pending `src/game/Graph.coffee` change

## 1. `refactor: Move game notifications onto GameEvents`

Stage 1. Claims: E2, E3, E5 (partial), E7, E8.

- [ ] Construct `Events` in `Naubino`'s constructor
- [ ] Add `GameEvents`, constructed in `Game`
- [ ] Move `outcome`, `level_up` (as `level_changed`), `chain_bonus`, `overflow_warning`, `basket_changed`
- [ ] `score_changed(points)` from `Scoring`
- [ ] `basket_changed(size)` carries the basket size
- [ ] Initial snapshot published after `attach`
- [ ] `Naubino.attach(game)` wires `Menu`, `Overlay`, `Background`, returns a disposer
- [ ] `MainButton` draws a cached score
- [ ] Remove `set_basket_size_provider`
- [ ] Exit check: no `game.mode` in `src/ui`, `Shapes.coffee`, `Naubino.coffee`
- [ ] Browser: score, level, bonus, basket, overflow glow all display

## 2. `refactor: Retire Session and make Game disposable`

Stage 2. Claims: O2, O3, E6, L1, L2, L3, L6, L7, L9, E5, E11.

- [ ] Commands (`play`, `pause`, `stop`, `toggle`) handled in `Game`
- [ ] Stop confirmation and loss sequence in `Game`
- [ ] `Game` dispatches `state_changed`, `lost`, `finished(snapshot)`
- [ ] Shell reacts: `Overlay`, `Background`, `Menu` button, highscore, `Audio`
- [ ] `start_game(mode)` for startup, finish, and mode switch
- [ ] `Game.dispose` clears timers, deactivates signals, unsubscribes
- [ ] Delete `Session.coffee`
- [ ] Browser: restart during destruction animations
- [ ] Browser: mode switch while ready, playing, paused
- [ ] Browser: loss sequence, stop confirmation cancel, highscore stored

## 3. `refactor: Remove run reset machinery`

Stage 3. Claims: L4, L5, E4, E12.

- [ ] Remove `configure_run`, `switch_mode`, `Graph.clear`, `World.reset_signals`, `previous_count`
- [ ] Rule constructors do setup; no `Rule.init`, no `start(from)`
- [ ] Naub and cycle signals moved onto `GameEvents`
- [ ] Remove `menu.button`, `menu.focus`, `menu.blur`, `game_draw`, `naub_unfocused`
- [ ] Exit check: no `configure_run`, `switch_mode`, `reset_signals`, `init:` in `src/modes`, `src/game`
- [ ] Browser: pause and resume keep elapsed time, new game starts at zero

## 4. `refactor: Lease game layers from Viewport`

Stage 4a. Claims: O5, V1, V2, V3, V11.

- [ ] `Viewport` creates canvases by depth, CSS classes instead of IDs
- [ ] `viewport.lease()` and `lease.release()`
- [ ] `Game` no longer extends `Layer`, leases its field layer
- [ ] `Background` moved into `Game`
- [ ] `GameLoop` advances shell layers plus current `Game`
- [ ] `canvas.style` only used in `Viewport`
- [ ] Browser: desktop and touch, restart leaves no stale canvas

## 5. `feat: Resize the game through Viewport`

Stage 4a. Claims: V9, V10.

- [ ] `Viewport.field_resized(width, height)` signal
- [ ] `Game` takes initial field size in its constructor
- [ ] `Game.resize` updates center, anchors, spawn bounds, physics bounds
- [ ] Browser: rotate a phone mid-game

## 6. `feat: Route pointer input through Viewport`

Stage 4b. Claims: V4, V5, V6, V7, V8, V12.

- [ ] Pointer Events on the container, `touch-action: none`
- [ ] Top-down routing with per-`pointerId` capture
- [ ] Mouse-only hover for `Menu`
- [ ] Tap on menu region opens it on touch
- [ ] Two-finger gestures recognized in `Viewport`
- [ ] `Input` keyboard-only, `pointer_*` signals removed
- [ ] Browser: menu tap never drags, drag over menu continues
- [ ] Browser: two-finger tap toggles pause, drops first finger's drag

## 7. `refactor: Split StandardGame and DebugGame from Mode`

Stage 5. Claims: O7, O8.

- [ ] `StandardGame` with rules, `DebugGame` with debug hooks
- [ ] `Mode` holds only data and named classes
- [ ] `main.coffee` picks game class and mode
- [ ] Browser: both modes play, debug gestures spawn

## 8. `refactor: Sync Graph from join topology events`

Stage 6. Claims: J6.

- [ ] Join IDs allocated outside `Graph`
- [ ] `join_added`, `join_removed` dispatched for every join
- [ ] `Graph` subscribes, `Naub.graph` removed
- [ ] Browser: silent factory pairs still form cycles, no join sound

## 9. `refactor: Move join operations into World`

Stage 7. Claims: O10.

- [ ] `join_with`, `split_join`, `replace_with` logic in `World`
- [ ] `Game.step` and `Factory` call `World`
- [ ] `Naub` has no physics access
- [ ] Browser: join, replace, rejected joins, cycles
