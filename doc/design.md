# Design

Target architecture for Naubino. Replaces `architecture-plan.md` and
`signal-transition-plan.md`.

Each claim has an ID and a **Check** you can verify against the source.
Claims describe the target state. `Status` says whether the code already
matches. Implement stage by stage (see [Stages](#stages)). Never break a
claim marked `done`.

The round-composition decisions below supersede the earlier data-only Mode and
game-subclass split. Revised claims are marked `partial` or `todo`, even where
the previous design was complete. All statuses were re-audited against `src/`
on 2026-11-17.
[round-composition.md](round-composition.md) retains the exploration and rationale;
this document records the agreed target and remaining decisions.

Rules for implementers:

- Read `AGENTS.md` first. Use Deno tasks. Writing and modifying tests is allowed.
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
| Mode | Selectable round recipe. Supplies configuration, constructs behaviors, and wires dependencies. |
| Rule | Gameplay behavior with optional lifecycle hooks. May be produced by a class or factory function. |
| World | Authoritative naub registry and owner of physical join, split, and replace operations. |
| Graph | Optional connection-analysis implementation, private to the rule that uses it. |
| Command | Signal that requests work. Exactly one handler. |
| Notification | Signal that reports something that already happened. Any number of subscribers. |

---

## Round composition

**A mode assembles a round. A game owns and runs it. Rules implement behavior.**

A mode may assemble different behavior sets, not just select a predefined
composition. Different mode implementations may hardcode their configurations;
shared helpers are optional. No separate Composition or Preset abstraction,
generic registry, service locator, or dependency-injection framework is required.

Construction proceeds in this order:

1. Snapshot the selected mode's current configuration, including nested values.
2. `Game` creates common infrastructure, including `World`, using the snapshot.
   It forwards consumer options without interpreting their nested settings.
3. Mode assembly receives explicit infrastructure dependencies, not `Game` itself.
   It constructs its naub factory, policies, rules, and other domain objects,
   configures them, and wires their dependencies and execution order.
4. Ownership of the assembled objects transfers to `Game`.
5. Once construction, wiring, and initial configuration are complete, `Game` may
   activate the rules. Nothing starts gameplay during construction.

Mode assembly takes a `RoundContext` and returns an `AssembledRound` (see
`types.d.ts`). Rule order in `AssembledRound.rules` is execution order. Activation happens on the `ready → playing` transition, right before
the first start. `ready` means constructed, hidden, and unpopulated.

The following TypeScript describes the intended contract, not a migration away
from CoffeeScript:

```typescript
interface Rule {
  activate?(): void;
  start?(): void;
  stop?(): void;
  check?(): void;
  dispose?(): void;
}
```

Initial population and gesture spawning are ordinary rules, not distinct rule
types. Factories, policies, Basket, physics, walls, and attachment constraints do
not become rules merely because a mode configures or owns them. Rules implement
active gameplay behavior; these other objects provide creation, decisions,
domain state, or simulation mechanisms.

Ownership and access are separate. In particular:

```text
Game
  World                         authoritative joins and physical mutations
    PhysicsWorld                bodies, walls, attachment constraints
  Round events
  Mode-assembled objects
    Naub factory                creates through World
    JoinPolicy                  decides collision actions
    Basket                      domain object used by rules
    Rules
      Spawner / Scoring / Overflow / Levels
      Initial population / Gesture spawning
      Connection analysis
        Graph                   private analysis implementation
```

Not every mode installs every object shown. The factory and other rules do not
access Graph directly. The connection-analysis rule observes committed topology changes
and exposes narrow queries where needed, such as a connected group for focus
highlighting. Menu button connections are visual and require neither Graph nor
World. Rendering must not require a host that implements simulation operations.

## Ownership

| ID | Claim | Check | Status |
|---|---|---|---|
| O1 | `Naubino` is the shell. It owns `Viewport`, `GameLoop`, `Input`, `Settings`, `Audio`, `Menu`, `Overlay`, highscores, `AppEvents`, and a reference to the current `Game`. | These are constructed in `Naubino.coffee` and nowhere else. | partial |
| O2 | `Game` is disposable. One instance per round. Restart, stop, and mode switch all dispose the current `Game` and construct a new one. | No method resets a live `Game` (`configure_run`, `switch_mode` don't exist). | done |
| O3 | `Session` does not exist. | `src/Session.coffee` is gone; `grep Session src` finds nothing. | done |
| O4 | `Game` owns common infrastructure and the lifetime of mode-assembled objects. Mode assembly may construct the factory, policies, rules, and domain objects; construction does not imply ongoing ownership by Mode. | `Game` creates World and drives disposal of the assembled round. No mandatory Graph field on Game. | partial |
| O5 | `Game` decides which layers it uses and owns them. It does not extend `Layer`. The shell registers the returned layers with `Viewport` and `GameLoop`. Mode-assembled renderers get layers through `RoundContext.lease_layer`; Game still owns and releases those leases. | `class Game` has no `extends Layer`; shell calls `viewport.set_layers` with `game.layers`. Mode code never touches `Viewport`. | partial |
| O6 | `Menu` and `Overlay` belong to the shell and survive games. | Both are constructed in `Naubino`, never in `Game`. | done |
| O7 | Mode supplies configuration and assembles a round through explicit construction and wiring. It receives no ongoing play, pause, or disposal callbacks and holds no live round timers or state. Mode carries no `id` or `version`; the shell owns mode identity. | `Mode.assemble(context: RoundContext): AssembledRound`. No Game, no `request_loss`; rules request loss via `loss_requested`. Every invocation produces fresh mutable round objects. | todo |
| O8 | A different composition or configuration does not justify a Game subclass. Standard and playground behavior is assembled by modes and implemented by rules and their dependencies. | No `StandardGame` or `DebugGame` exists. One `Game` class hosts every mode. | todo |
| O9 | `active_tree` and `focused_naub` are `Game` interaction state. | Fields on `Game`, not `World`. | done |
| O10 | World owns authoritative joins, join IDs, and join, split, and replace operations. Naub keeps visual and local state only; callers request mutations through World. | Naub never reaches through a layer to Graph, physics, object lookup, or join mutation services. Factory creates connections through World. | todo |
| O11 | Graph is an optional analysis implementation private to a connection-analysis rule, not a required Game or Menu service. It knows no Game, Layer, physics, or event bus. | The rule feeds structural changes into Graph, publishes cycle outcomes, and provides narrow queries. Menu has no Graph. | partial |
| O12 | Rules receive only the concrete objects, signals, queries, and operations they need. | No rule receives Game, the whole `RoundContext`, or a generic resource/service locator. | todo |
| O13 | Only timers, subscriptions to longer-lived signals, and viewport leases outlive an unreachable `Game`. Their owner releases them on dispose. Other round objects (factory, policies, Basket, World, Graph) need no disposal. | No disposer lists or registration API for non-rule objects. | partial |

## Configuration

| ID | Claim | Check | Status |
|---|---|---|---|
| C1 | Application preferences, round configuration, and mutable runtime state are separate. Settings is not the catch-all source of gameplay tuning. | Audio, theme, and graphics remain preferences; selected mode configuration supplies gameplay tuning. | partial |
| C2 | Mode configuration can change between rounds. Every new round gets an isolated snapshot, including nested values; running a round never mutates that snapshot. A configuration may carry an optional friendly `name`; the shell copies it into the stored `ScoreSnapshot` as `config_name`. | Changing the source configuration affects the next round, not an existing round. Progression tables are not live runtime state. | todo |
| C3 | Consumers own their configuration defaults and merging. Game forwards options without understanding nested physics or spawn settings. | No nested spring merge or spawn-probability interpretation in Game. | todo |
| C4 | Modes can supply and configure different naub factories. The factory is constructed during assembly using the round's explicit dependencies. | Game does not unconditionally construct one specific naub factory. | todo |
| C5 | Center attraction and edge tethering are independent physical attachments and may coexist on a naub. Edge tethers last for that naub's lifetime and are cleaned up on removal. | Adding a tether does not implicitly replace the center spring; attachment selection is not hardcoded in Game.add_object. | todo |
| C6 | Every round value has one owner. `Scoring` owns points, cleared naubs, and duration. `Basket` owns its capacity. `Spawner` owns its spawn parameters. `Levels` owns the level. Nothing is stored on `Game`. | No rule writes fields onto `Game` or into another object's fields. | todo |
| C7 | `Levels` pushes level parameters: `Spawner.configure` and `Basket.set_capacity`. It reads progress through a narrow `Progress` query backed by `Scoring`. It applies level 0 in its constructor. Levels is the only writer of those parameters; revisit if another writer appears. | Spawner and Basket do not depend on Levels. | partial |
| C8 | Mode assembly builds `RoundResults` as a small object over `Scoring` and `Levels`. `Scoring` knows nothing about levels. | No `score_snapshot` on Game or its subclasses. | todo |

Shadow types for these are in `types.d.ts` (`Progress`, `SpawnParameters`,
`Spawner`, `Basket`, `RoundResults`).

## Events

| ID | Claim | Check | Status |
|---|---|---|---|
| E1 | Events use the existing `Signal` class with concrete named signals. No string event names, no new event library. | `grep "new Signal\|new Naubino.Signal" src` covers all event definitions. | done |
| E13 | `Signal.add` accepts an optional `AbortSignal`, using native `addEventListener` `{signal}`. Subscriptions that outlive a round use their owner's `AbortSignal` instead of stored unsubscribe functions. Deactivation (E11) stays separate. | No `@subscriptions` arrays in `Game` or rules. `Game` owns one `AbortController`; a rule that unsubscribes on stop uses one controller per start/stop cycle. | todo |
| E2 | `AppEvents` (page lifetime) holds `input`, `commands`, and settings/theme notifications. It holds nothing about score, level, basket, overflow, or outcome. | `src/Events.coffee` has no `game` namespace. | done |
| E3 | `AppEvents` is constructed in `Naubino`'s constructor, not as a class-body property. | No `events: new Events()` at class level in `Naubino.coffee`. | done |
| E4 | Each Game owns round-scoped signals for simulation outcomes and outward notifications. World publishes committed structural outcomes through explicit notification dependencies; the connection-analysis rule publishes cycle outcomes. | Graph knows no event bus or host; event wiring is explicit. One `GameEvents` object per round holds both internal and outward signals, all typed (E5). | partial |
| E5 | Outward `GameEvents`: `state_changed(state)`, `score_changed(points)`, `level_changed(level)`, `chain_bonus(points)`, `overflow_warning(severity)`, `lost(reason)`, `finished(snapshot)`, plus sound cues. No basket signal; the mode renders its basket itself. | Signals exist with those payloads (`GameEvents` in `types.d.ts`). | partial |
| E6 | Game handles common lifecycle commands. Mode assembly wires existing application input signals into input-driven rules as explicit dependencies. Rules subscribe on start, unsubscribe and cancel input work on stop, and clean up defensively on dispose. | Gesture spawning has no whole application-bus or Game dependency and receives no input while stopped. Host subscriptions are also removed on disposal. | partial |
| E7 | UI never references `Game`, `Mode`, rules, or `World`. The shell's `attach(game)` is the only code that knows both sides. It returns a disposer. | `grep -E 'game\.|\.mode\.' src/ui src/game/Shapes.coffee` finds no traversal; `MainButton` draws a cached value. | done |
| E8 | Payloads carry the data consumers need. A new `Game` publishes its initial `Scoreboard` (score 0, level 0) after `attach`, or nothing if the round has no `RoundResults`. | `set_basket_size_provider` is gone; the published values come from `RoundResults.scoreboard()`. | partial |
| E9 | A command has one handler. A request is not proof of completion: rules dispatch `loss_requested(reason)`, `Game` alone handles it and may refuse, and only a completed FSM transition dispatches `lost(reason)`. Listener return values are never used. | No rule calls `loose`; `Overflow` dispatches `loss_requested`. No caller reads a listener return value. | todo |
| E10 | A multi-part mutation happens inside one owner. Only the committed result is published. Correctness never depends on subscriber order. | `Levels` dispatches `level_changed` only after `load_level` has applied all parameters. | todo |
| E11 | `GameEvents` signals are deactivated on dispose. Late callbacks from a disposed game reach no subscriber. | `dispose` sets `active = false` on every `GameEvents` signal. | done |
| E12 | Unused signals are removed: `menu.button`, `menu.focus`, `menu.blur`, `Game.game_draw`. Remove `naub_unfocused` unless a consumer appears. | `grep` finds no definitions. | done |

## Lifecycle

| ID | Claim | Check | Status |
|---|---|---|---|
| L1 | `Game` FSM states: `ready`, `playing`, `paused`, `lost`, `finished`. `finished` is terminal and dispatches `finished(snapshot)` exactly once. | FSM config in `Game.coffee`. | done |
| L2 | On `finished` the shell stores the highscore, calls the `attach` disposer, disposes the `Game`, constructs the next one, and attaches it. | `start_game` performs replacement; the finished handler stores the result before calling it. | done |
| L3 | Game disposal stops and disposes rules, cancels its own timers, aborts its `AbortController`, deactivates round signals, and releases its viewport leases. Each rule cleans up its own timers and subscriptions. Repeated disposal is harmless. | Restart during delayed work cannot affect the replacement round. Stopping a rule is not a substitute for disposing it. `Game.dispose` calls `dispose` on every rule, activated or not. | partial |
| L4 | Rule is a structural contract with optional activate, start, stop, check, and dispose hooks. Class instances and factory-created objects are equally valid. Start/stop mean play/pause, not initialization or reset. | Game calls supported hooks; no mandatory Rule superclass or empty hook methods. | todo |
| L5 | Object IDs start at 1 in every `Game`. | Each `World` starts its own `objects_count` at zero. | done |
| L6 | Stop confirmation happens in `Game` before entering `finished`. Every round confirms, in every mode; debug mode behavior is not fixed and may follow later. | `confirm_stop` called from `Game`'s FSM; no per-mode override. | partial |
| L7 | The loss sequence (grey out, fade, wait, finish) lives in `Game`. `Overlay` shows the warning by reacting to `lost(reason)`. | No `Overlay` call inside `Game`. | done |
| L8 | Construction, wiring, and initial configuration finish before activation can spawn naubs or start gameplay. A factory may further configure a rule before returning it. Activation occurs on the `ready → playing` transition. | Spawner construction never spawns. Level 0 parameters are applied during construction, before the first spawn. A round disposed while `ready` never spawns. | todo |
| L9 | Mode switch = finish without result + construct a `Game` with the new mode. | No `finished` snapshot is stored for a mode switch. | done |
| L10 | Game activates each rule once per round before its first start. Pause/resume never reconstructs or reactivates it. Start is not called twice without an intervening stop. | One-shot population runs once; resume only restarts ongoing work. | partial |
| L12 | Game runs `check` every 300 ms while `playing`, over `AssembledRound.rules` in order. One ordered list covers all hooks. The pass ends as soon as the round leaves `playing`, so nothing runs after a loss, pause, or stop triggered inside the pass. `check` returns nothing meaningful; rules end the round only through command signals such as `loss_requested`. | `Game.check` tests `@current is 'playing'` before each rule. No caller reads a `check` return value. | partial |
| L11 | Rule disposal is safe before activation and while stopped. Disposal permanently prevents further work. | Disposing an unplayed round releases its resources without requiring activation. | todo |

## Viewport

| ID | Claim | Check | Status |
|---|---|---|---|
| V1 | `Viewport` creates its canvases ordered by depth, distinguished by a CSS class rather than an `id`. | No `setAttribute 'id'` in `Viewport.coffee`; canvases carry a depth class. | done |
| V2 | `viewport.lease()` hands out a layer a `Game` can draw into; `lease.release()` returns it. | `lease`/`release` exist on `Viewport`; `Game` calls them instead of constructing its own layer. | done |
| V3 | `Game` does not extend `Layer`. It leases its field layer from `Viewport` instead. | No `extends Layer` on `class Game`. | done |
| V4 | `Viewport` listens for Pointer Events on the container. The container has `touch-action: none`. | Pointer listeners and container/leased-canvas `touch-action` are set by `Viewport.coffee`. | done |
| V5 | Pointer routing is top-down over `@layers`, with a per-`pointerId` capture: the first layer that accepts a pointer keeps it until `pointer_end`/`pointer_cancel`. | `pointer_down` walks `@layers.slice().reverse()`; `@captures[pointer_id]` holds the chosen layer. | done |
| V6 | Hover (`pointer_move` with no active capture or gesture) is routed to `Menu` only for mouse pointers. | `pointer_move` checks `event.pointerType is 'mouse'` before forwarding to the menu layer. | done |
| V7 | A tap on the menu's region opens it even when the pointer is a touch pointer. | `Menu.accepts_pointer` and `Menu.pointer_start` are reached by `pointer_down` regardless of `pointerType`. | done |
| V8 | Two-finger gestures (pause toggle, drag cancel) are recognized and tracked in `Viewport`, not `Input`. | Gesture state (`@gesture`, `@active_pointers`) lives in `Viewport.coffee`; `Input.coffee` has none. | done |
| V9 | `Viewport` dispatches a `field_resized(width, height)` notification instead of calling a resize callback directly. | A `Signal` named `field_resized` on `Viewport` or `AppEvents`; no `@on_resize` callback property. | done |
| V10 | `Game` takes its initial field size in the constructor. Layout preserves world coordinates, anchors, walls, and physics bounds. Browser-native rotation is the default; compensation is optional. | `Game.resize` updates only `view_bounds`; `Viewport` applies the selected view transform and inversely maps pointer input. | done |
| V11 | `canvas.style` is only read or written inside `Viewport`. | `grep "canvas.style" src` has no hits outside `Viewport.coffee`. | done |
| V12 | `Input` is keyboard-only. The `pointer_start`/`pointer_move`/`pointer_end` signals are removed from `Events`. | `Input.coffee` takes no `canvas`/`viewport`; `Events.input` has no `pointer_*` keys. | done |

## Joining and simulation

| ID | Claim | Check | Status |
|---|---|---|---|
| J1 | World allocates join IDs and consistently updates physical constraints and connection state. Graph indexes those committed joins; it never allocates authoritative IDs. | Creating, splitting, or replacing joins requires no Graph instance. | partial |
| J2 | Gameplay callers request joins and replacements through World, not Naub or Graph. Do not add consumers of the old Naub mutation return values. | Factory and collision-action execution use World operations. | todo |
| J3 | `JoinPolicy.check_joining` returns `{action: 'join' \| 'replace', pair}` or `null`, never `false`. It does not mutate queues. `Game.check_joining` queues and returns a boolean. | Every return path in `JoinPolicy.coffee` is explicit and returns a `JoinAction` or `null`. `JoinPolicy` never touches `joining_naubs` or `replacing_naubs`. | todo |
| J4 | Collision-triggered joins and replaces are queued and executed after the physics step. | `Game.step` drains queues after `physics.step`. | done |
| J5 | Factory joins (`create_naub_pair`, `create_naub_triple`) complete synchronously. | No queue used in `Factory`. | done |
| J6 | Committed structural notifications (`join_added(id, first, second)`, `join_removed(id)`) report every join, including silent ones. Feedback (`naub_joined`) may be suppressed. The connection-analysis rule updates its private Graph from structural outcomes. | Graph does not subscribe itself; join correctness never depends on an observer. | partial |
| J7 | Cycle evaluation runs only after a replacement has finished rewiring. | `naub_replaced` dispatched after all rewiring. | done |
| J8 | `naub_destroyed` means destruction *started*, not removal. | Dispatched in `Naub.destroy`, before the removal timeout. | done |
| J9 | Composition makes required execution order explicit. Preserve Overflow checking before Levels can grow the basket. Do not rely on event subscriber order for multi-part mutations. | Mode assembly expresses the constraint through rule order. After a loss request, the pass ends (L12). | partial |
| J10 | Debug auto joining disables the focus/drag requirement and minimum-force threshold through join-policy configuration. Other joining behavior is unchanged. | Auto joining does not introduce a new replacement-selection mechanic. | todo |

## Keep as direct calls

Do not turn these into signals:

- Queries: connected-group queries exposed by connection analysis,
  `World.get_object`, `World.naub_at`, local naub connectivity queries,
  `Basket.capacity`, `basket_size`, result snapshots. Graph's implementation
  methods are not general round services.
- Factory calls whose return value gets customized right away.
- Mode assembly, World mutations, explicit control operations such as requesting
  loss, and rule hooks (`activate`, `start`, `stop`, `check`, `dispose`).
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

Historical stage, completed under the earlier design. Claims L4 and E4 have since
been revised; their remaining work is covered by the stages below. L5 and E12
remain unchanged.

1. Remove `configure_run`, `switch_mode`, `Graph.clear`, `World.reset_signals`,
   and the `previous_count` parameter.
2. Rule constructors do setup. Remove `Rule.init` and `start(from)`.
   `Scoring` sets `begin_time` on first `start`.
3. Move naub and cycle signals from `World`/`Graph` onto `GameEvents`.
   `Naub` dispatches through the game's events.
4. Remove unused signals (E12).

Exit check: `grep "configure_run\\|switch_mode\\|reset_signals\\|init:" src/modes src/game` is empty.

### Stage 4: Game owns its layers

Claims: O5, V1, V2, V3, V11.

1. `Game` stops extending `Layer`. It leases its field and background
   canvases from `Viewport` and releases them on dispose.
2. The shell registers `game.layers` with `Viewport`; `GameLoop` advances
   the shell layers and current `Game`.

Resize follow-up (V9, V10): `Viewport.field_resized` notifies the current
`Game`, which unsubscribes on disposal. The constructor receives the initial
field size after initial layout. World coordinates, physics bounds, bodies,
anchors, walls, and drag state remain unchanged by layout. Browser-native
rotation is the default; `graphics.compensate_rotation` defaults to false.
Experimental compensation for the game and background layers can be enabled
with `?compensate_rotation=true` or changed through `Settings.set` at runtime.
It does not configure individual objects. Menu and overlay stay upright in
browser coordinates. Pointer routing applies the inverse selected world
transform for game input, including captured drags.
Changes to the visible world dimensions dispatch `field_resized` and update
`Game.view_bounds` for camera framing and Factory spawning without moving
the world. With compensation enabled, a pure rotation keeps these dimensions
unchanged and does not dispatch `field_resized`. Screen Orientation API changes and legacy iOS
orientation changes are handled and unsubscribed by `Viewport`.
Default overlay messages stay centered, including their scaling pivot.
Explicit text coordinates stay fixed. Layout repaints paused messages without
advancing their animations.

### Stage 5: Game subclasses, Mode as data (superseded)

This earlier direction moved composition and debug behavior into StandardGame
and DebugGame and restricted Mode to data. Those subclasses now exist, but they
are an intermediate state, not the target. Stages 8 and 9 replace this split with
mode assembly and explicit rule lifecycle handling. Do not extend the old split.

### Stage 6: Graph observes topology

Implemented; automated checks pass except the documented lint baseline. Browser
play-testing remains pending. J6, O11, and J1 are partial because rule ownership
and World-owned mutations land in later stages.

Claims: J6; prepares O11 and J1.

1. Allocate join IDs outside Graph, temporarily in the existing mutation owner
   until Stage 7 moves them into World.
2. Publish structural join notifications independently of feedback sounds.
3. Feed Graph through explicit wiring; Graph no longer reaches into a host or
   dispatches cycle signals itself. Evaluate cycles only after full replacement.
4. Remove Naub's Graph dependency and Menu's unnecessary Graph instance.

Game currently allocates join IDs and feeds its Graph from structural signals.
Naub commits connection and constraint changes before publishing them, including
silent joins. Graph returns cycle lists; the host publishes them only after
`naub_replaced`. Stage 7 moves allocation and mutations into World; Stage 9 moves
the analysis wiring and Graph ownership into an optional rule.

Regression coverage: `deno task test` checks cycle discovery order, silent factory
pairs, splitting from either endpoint, joins without analysis, and complete
replacement before cycle evaluation.

### Stage 7: World owns joins

Claims: O10, J1, J2, J3; preserves J4, J5, J6, J7.

1. Move join ID allocation and join, split, and replace logic into World.
2. Game's collision-action execution and Factory call World. Keep collision
   mutations deferred until after the physics step and factory joins synchronous.
3. Naub loses host traversal for graph, physics, and structural mutation work.
   Render-only menu naubs require no simulation host.
4. Publish structural outcomes only after the corresponding mutation commits;
   evaluate cycles after replacement has completely rewired the connections.

### Stage 8: Separate construction and activation

Claims: L3, L4, L8, L10, L11, L12, E6, E13, O13.

The existing `StandardGame` and `DebugGame` may bridge this stage: wire rules
and input signals there until Stage 9 moves that wiring into mode assembly.

1. Add the optional `AbortSignal` to `Signal.add` (E13). Replace `Game`'s
   `@subscriptions` with one `AbortController`.
2. Support optional Rule hooks for class instances and factory-created objects.
3. Finish construction and initial configuration before invoking activation.
   Move Spawner's constructor spawn and playground's initial population into
   activation. Apply initial level parameters before either can spawn.
4. Activate once; start/stop only for play/resume and pause/leave-playing.
5. Move mode-specific gesture behavior into a rule with explicit input signals.
   Subscribe on start and cancel subscriptions and timers on stop and dispose.
6. Dispose rules, including unactivated ones, without allowing late work to
   affect the next round.

Exit check: construction starts no gameplay; activation runs once; repeated
pause/resume does not duplicate population, subscriptions, or timers.

### Stage 9: Mode assembles the round

Claims: O1, O4, O7, O8, O11, O12, E9, E10, C1, C6, C7, C8, C2, C3, C4, E4, J9.

Before implementation, trace standard and playground dependencies and settle the
assembly API, shared-state ownership, schedule, and result-provider boundary.
Do not introduce generic factories, resource containers, or schedulers to avoid
those decisions.

1. Snapshot the selected mode's current configuration for each round. Consumers
   own defaults and merging; Game only forwards infrastructure options.
2. Create common infrastructure, then invoke mode assembly with explicit
   dependencies and narrow lifecycle operations, never Game itself.
3. Let the mode construct the naub factory, join policy, domain objects, and rules
   and transfer their lifetime ownership to Game.
4. Install connection analysis as an optional rule owning a private Graph.
   Factory uses World; highlighting receives only its needed connectivity query.
5. Replace rule access to Game with explicit dependencies and wire required order.
6. Move standard and playground composition out of game subclasses. Remove
   subclasses whose only remaining purpose is composition or mode gameplay.
7. Keep mode identity and between-round configuration selection in the shell;
   restart assembles fresh objects using a new configuration snapshot.

Exit check: standard and playground run on the common host; a mode may omit
connection analysis entirely; editing mode configuration affects only new rounds.

### Backlog

- Fold `DragSystem` into `Game` (not scheduled).
- Theme and effects notifications on `AppEvents` (`theme_changed`,
  `effects_changed`), replacing scattered recolor and rate refresh calls.
- `CollisionHandler` dispatching `collision_observed` instead of calling `Game`.
- Deferred: configure debug auto joining without drag or minimum-force checks (J10).
- Deferred: support mode-selected walls and permanent edge tethers alongside independent
  center attraction (C5). These physical options do not require new rule types.
- Mode-owned basket renderer on a leased layer, replacing basket drawing in
  `Background` and the `basket_changed` signal.
- A populated but frozen pre-play field, if ever needed, gets its own FSM state
  between `ready` and `playing` (e.g. `set`). Activation moves to `ready → set`;
  the Rule hooks do not change. Not needed today.

---

## Validation

Build, after every stage:

- `deno task check`
- `deno task test`
- `deno task build`
- `deno task lint` (14 overlong level-table rows in `StandardMode.coffee` are pre-existing)

Browser, after every stage:

- Join, replace, and rejected joins work.
- Silent factory pairs update connection analysis, when installed, without a join sound.
- Menu buttons render and interact without Graph or a simulation host.
- World joins work without installing connection analysis.
- Construction spawns nothing; initial configuration precedes activation effects.
- Activation runs once; pause/resume never duplicates rules or input subscriptions.
- A changed nested mode configuration affects the next round, not the current one.
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






None.
