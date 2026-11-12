# Signal transition plan

Status: proposed. This document records the audit and migration direction;
it does not imply that the transition has been implemented.


## Goal

Separate application-wide communication from current-run communication,
and reduce cross-component traversal such as
`Naubino.game.mode.scoring.points` and `naub.world.naub_destroyed`.

Use signals for commands and notifications at meaningful ownership
boundaries. Keep queries, ordered lifecycle execution, and internal
algorithms explicit.

This revises the architecture plan's rule that a signal must live on its
producer. The producer still dispatches it, but a shared event contract
can own the signal.

## Lifetimes

| Lifetime | Survives restart | Survives mode switch | Examples |
| --- | --- | --- | --- |
| Application | Yes | Yes | Input, settings, session, UI |
| Game instance | Yes | Yes | Run replacement, mode changes, rendering |
| Current run | No | No | Joins, destruction, cycles, scoring, rule coordination |

Use two event objects, not three:

- A persistent application hub. Its `game` namespace also carries
  game-instance lifecycle and UI-facing outputs.
- A fresh, mode-selected run hub, replaced on restart and mode switch.

An event produced by a run does not necessarily need a run-local signal
object. For example, Menu should subscribe to score updates once and keep
that subscription across restarts.

Mode activation is a separate subscription lifetime, not necessarily a
third bus. Mode input bindings survive restarts but unsubscribe on mode
switch. Run-local subscriptions are rebuilt each run.

## Proposed placement and API

Keep event definitions in `src/Events.coffee`. Retain the existing concrete
`Signal` implementation rather than introducing string event names or a
new dependency.

Proposed shape, with names subject to implementation review:

```text
Events                              persistent application hub
    input
    commands
    session
    settings
    game                            lifecycle and outward presentation

RunEvents                           fresh each run
    common simulation commands
    common simulation notifications

StandardRunEvents extends RunEvents  only genuinely mode-specific signals
DebugRunEvents extends RunEvents     only if DebugMode needs additions
```

Add `Mode.events(game)` alongside `rules`, `graph`, and `join_policy` so a
mode can construct its run event set. Avoid empty subclasses if a mode
only uses the common events.

Construct `@events = new Events()` inside `Naubino`'s constructor. The
current class-body `events: new Events()` shares the hub between instances.

`Game.configure_run()` owns replacement of the run hub. Inject the exact
run instance into participating objects. Old callbacks must never resolve
the new run hub dynamically through a persistent Game reference.

### Commands versus notifications

- Commands request work and have one authoritative handling owner.
- Notifications announce an occurrence or committed state and may have
  multiple subscribers.
- A request is not evidence of successful completion. For example,
  `loss_requested` and `run_lost` have different meanings.
- Signals remain synchronous unless a handler explicitly schedules work.
  Dispatching a command does not authorize mutation inside a physics step.
- Do not use listener return values as an implicit response protocol.
- Prefer payloads containing the data consumers need over notifications
  that force consumers to traverse Game, Mode, or World.

## Existing signal inventory

The audited active source declares 26 signals: 19 in `Events`, five on
`World`, one on `Graph`, and one on `Game`.

### Persistent signals

| Existing signal(s) | Producer and consumers | Transition |
| --- | --- | --- |
| `input.pointer_start`, `pointer_move`, `pointer_end` | Input to Game and Menu | Keep application-wide |
| `input.two_finger_start`, `two_finger_end` | Input to DebugMode | Keep application-wide; mode owns subscription cleanup |
| `input.two_finger_tap` | Input to StandardMode | Keep application-wide; mode owns subscription cleanup |
| `commands.play`, `pause`, `stop`, `toggle` | Input, Menu, StandardMode to Session | Keep application-wide |
| `session.state_changed` | Session to Input gesture cancellation | Keep; consider Menu as another consumer |
| `game.outcome` | Game to Session | Keep persistent; clarify accepted outcome semantics |
| `game.overflow_warning` | Overflow to Background adapter | Keep outward presentation contract |
| `game.basket_changed` | Levels to Background redraw adapter | Add presentation data so Background need not query Mode |
| `game.level_up` | Levels to Overlay adapter in Session | Keep outward presentation contract |
| `game.chain_bonus` | Scoring to Overlay adapter in Session | Keep outward presentation contract |
| `menu.button`, `focus`, `blur` | No active dispatch or subscription found; `button.active` is assigned | Remove unless a real use is established |
| `Game.game_draw` | Game; no active subscriber found | Remove, or move to persistent `game.rendered` if needed |

### Run-local signals

| Existing signal | Producer and consumers | Transition |
| --- | --- | --- |
| `World.naub_joined` | Naub to Audio | Move to run hub; bridge feedback to persistent Audio if needed |
| `World.naub_destroyed` | Naub to Scoring and Audio | Move to run hub; clarify destruction-start semantics |
| `World.naub_replaced` | Naub to GraphWiring/DebugMode and Audio | Move to run hub |
| `World.naub_focused` | Naub to StandardMode GraphWiring | Move to run hub |
| `World.naub_unfocused` | Naub; no active subscriber found | Move if retained, otherwise remove after checking intended use |
| `Graph.cycle_found` | Graph to Scoring and GraphWiring/DebugMode | Move to run hub |

`Settings.watch` is an additional callback-based notification mechanism,
not part of the 26-signal count. It can publish through the persistent
settings namespace while retaining `Settings.set/toggle` as the mutation
API. Native DOM events remain at browser adapters rather than being
forwarded indiscriminately.

`src/Tutorial.coffee` is a legacy AMD-style artifact outside the active
application entry path. Its obsolete signal usage is not included in this
migration unless the tutorial is revived.

## Joining: verified return-value contracts

`Graph.add_join()` returns an ID that is used by `Naub.join_with()` as the
key for constraints, both naubs' partner maps, and drawing state.

The result of `Naub.join_with()` is not consumed by active callers in
Game, Factory, or replacement logic. The result of `Naub.replace_with()`
is also unused.

Therefore the return value does not prevent event-driven joining. It
means that the complete join operation needs an owner that can perform
its internal bookkeeping synchronously.

### Proposed join boundary

```text
CollisionHandler
    collision_observed(first, second, impulse)

JoinPolicy
    evaluates collision
    join_requested(first, second)
    replace_requested(first, second)

Run operation owner
    queues collision-triggered work until physics stepping completes
    executes graph/physics/naub mutations as one operation
    publishes structural changes and optional presentation feedback
```

Initially the operation owner can remain Game's existing scheduling path.
Do not create a new class solely to rename that responsibility.

Factory-created pairs need synchronous completion before the factory
operation finishes. Define whether they use the same command with an
explicit execution context or invoke the operation handler directly. Do
not accidentally defer initial pair construction to the next frame.

### Removing Naub's Graph dependency

Two viable stages:

1. Move the entire join/split/replace operation behind a command handler;
   the handler can still call `Graph.add_join()` internally.
2. If Graph becomes a projection of topology, allocate join IDs outside
   Graph and let it consume structural notifications:

```text
join_added(id, first, second)
join_removed(id)
    -> Graph updates its topology
    -> cycle_found(ids), at the appropriate evaluation boundary
```

Do not assume stage 2 is a mechanical signal replacement. ID allocation
and topology ownership must be decided together.

Structural notifications must be distinct from feedback:

- `join_added` is emitted for every join, including silent factory joins.
- Join feedback can be suppressed for silent joins.

The existing `naub_joined` has no payload and is suppressed for silent
joins. It cannot serve as Graph's structural synchronization event.

Replacement must complete its topology changes before cycle evaluation.
Do not evaluate a partially rewired graph.

## Direct simulation-call candidates

Names below are proposed, not implemented APIs.

| Current boundary | Candidate signal or ownership change | Constraint |
| --- | --- | --- |
| CollisionHandler to `Game.check_joining` | `collision_observed` | Extract impulse synchronously; do not retain the physics arbiter |
| Game to `JoinPolicy.check_joining` | Policy consumes collision and emits join/replace requests | One authoritative policy; replacing the decision return is optional |
| `Game.step` to `Naub.join_with` | Join command handler | Preserve post-physics scheduling |
| `Game.step` to `Naub.replace_with` | Replacement command handler | Preserve complete operation ordering |
| Factory to `Naub.join_with` | Shared join operation | Initial joins must complete synchronously |
| Naub to `Graph.add_join` | Handler owns Graph call, or `join_added` projection | Returned ID is currently consumed |
| Naub to `Graph.remove_join` | `join_removed` | Keep graph, partners, and constraints consistent |
| Naub to physics join/unjoin | Join operation owns physics mutations | Do not distribute one operation across independent listeners |
| `Naub.attracted_to` to physics attraction | Object-registration operation owns attraction | Move constraint-handle bookkeeping with the operation |
| `Naub.replace_with` to `Game.unfocus` | `interaction.release_requested` | Preserve interaction cleanup before replacement completes |
| GraphWiring/DebugMode to `Graph.cycle_test` | Graph consumes replacement completion | No caller consumes the cycle-test result |
| GraphWiring/DebugMode to `Game.destroy_naubs` | Destruction owner consumes cycles or `destroy_requested` | Preserve immediate disabling and batch registration |
| Game to `Naub.destroy` | Destruction command owner | Keep batching, animation start, and timers together |
| Naub removal and eventual world removal | `remove_requested` plus removal notification | One complete cleanup operation, not unordered fragments |
| Game/Factory to object registration | Add command and `object_added` | IDs and physics metadata must exist before later construction uses them |
| Spawner to Factory creation | `spawn_requested(spec)` | Spawner ignores results; preserve initial-spawn timing |
| DebugMode to Factory creation | Spawn command and completion notification, or retain factory calls | Debug immediately decorates new objects |
| Overflow to `Game.loose` | `loss_requested(reason)` | Accepted loss remains a separate notification |
| GraphWiring sets active tree after `Graph.tree` | `active_tree_changed(ids)` if interaction needs a notification | Tree calculation remains an ordinary query inside the owner |
| Levels writes Basket/Spawner configuration | Committed mode-local level configuration | Apply a complete configuration before publishing completion |

### Keep queries direct

These currently return information immediately needed by the caller:

- Graph tree and partner queries.
- World lookup and hit-testing.
- Naub relationship predicates.
- Basket capacity and geometry calculations.
- Mode result snapshots and stop confirmation.
- Factory calls whose returned objects are immediately customized.

Moving responsibility may eliminate a query at a particular call site.
Replacing queries with request/response broadcasts is not itself a goal.

## Application and UI transition candidates

| Current coupling | Proposed transition | Notes |
| --- | --- | --- |
| MainButton reads `Naubino.game.mode.scoring.points` | Persistent `game.score_changed` | Menu caches display data; shape draws local data |
| Background provider reads `game.mode.basket` | Payload-bearing `game.basket_changed` | Supply presentation geometry rather than Mode or Basket |
| Session calls `menu.check_game_state(game)` | Menu consumes committed state notification | Establish whether Session or Game state is the intended contract |
| Session invokes `on_finished(snapshot)` | Persistent `game.run_finished(snapshot)` | Carry the captured previous-run result |
| Game calls `Naubino.audio.connect_to_game` | Audio consumes run-ready notification or persistent feedback | Audio owns subscription cleanup; avoid duplicate subscriptions |
| Session adapts level/bonus signals to Overlay | Overlay-owned subscriptions | No extra signal hop required |
| Naubino adapts warning/basket signals to Background | Background-owned subscriptions | No extra signal hop required |
| Session calls Overlay warning on loss | Overlay consumes accepted loss notification | Do not display an unaccepted request as a completed loss |
| Scattered theme recolor/redraw calls | Application `theme_changed` | Apply settings first; avoid duplicate recoloring |
| Controls refreshes each layer's rates | Application `effects_changed` | Each layer or one presentation owner applies rates |
| Input/Menu toggles settings | Retain `Settings.set/toggle`, optionally command signals | Existing mutation API already has one owner |
| `Settings.watch` | Application settings notifications | Preserve path/value payloads and unsubscribe behavior |
| Controls invokes layout callback | `fullscreen_changed` or `layout_requested` | Preserve immediate and delayed layout passes |
| Browser resize/orientation invokes Viewport | Optional layout command | Native events already provide a boundary |
| Startup calls Menu.open | Optional `menu_open_requested` | Preserve touch-startup behavior |
| External mode selection calls Game | `mode_change_requested`, then committed `mode_changed` | One transition coordinator |
| External play/pause/stop forwarding | Reuse existing application commands | Do not duplicate command families |

### Presentation initialization and reset

Signals do not replay previous values automatically.

- Install presentation subscriptions before publishing initial snapshots.
- Cache score on Menu or another persistent presentation owner, not a
  transient button shape that may not exist yet.
- Publish initial score and geometry after run configuration is committed.
- Publish cleared/absent values when a mode does not provide scoring or a
  basket. Switching to DebugMode must not retain StandardMode's display.
- Keep final-result payloads independent of live rules. Session currently
  captures the previous result before stop and reports it after reset.
- Prefer data snapshots to exposing Game, Mode, or rule objects as the
  long-term presentation contract.

## Mode-specific events

Only events used to coordinate a mode's internal behavior belong in that
mode's run-event extension. Common simulation vocabulary stays on
`RunEvents`.

A StandardMode-produced event is not automatically StandardMode-specific:
score display, warnings, messages, and playfield presentation can use
outward contracts understood by the application without knowing the
mode's internal rules.

Potential StandardMode-local events include committed level
configuration and rule-specific progression notifications. DebugMode
needs no additional events merely because it has a different name.

StandardMode's two-finger-tap binding and DebugMode's spawning-gesture
bindings remain application input subscriptions owned by the active mode.
They survive run rebuilds and unsubscribe on mode switch. Gesture timers
must stop on pause, reset, mode switch, and disposal as appropriate.

## Keep ordered execution explicit

Do not replace these operations with independent broadcast listeners:

| Operation | Reason |
| --- | --- |
| Session init/play/pause/stop across layers | Pause checks and stop confirmation can reject transitions |
| World/Graph/policy/rule construction | Required return values and explicit construction order |
| Rule init/start/stop/check | StandardMode depends on ordering |
| Mode lifecycle hooks | Ownership and cleanup contracts, not just notifications |
| Loss grey-out, fade, delayed stop | Completion-dependent workflow with timers |
| Viewport resize, scale, redraw | Avoid drawing a partially updated layout |
| Frame advancement and physics stepping | Ordered scheduler execution |
| Local shape rendering, styles, animation helpers | Internal implementation, not cross-component communication |
| App setup/disposal, input binding, loop start/stop | Deterministic resource ownership |
| Fullscreen request/result and highscore prompt/storage | Browser completion and persistence belong to their owners |

These operations may publish committed lifecycle notifications afterward.

## Migration sequence

Implement in independently reviewable steps. Do not mix the whole audit
into one behavior-changing rewrite.

### 1. Establish event lifetimes

- Construct application Events per Naubino instance.
- Define common RunEvents and the Mode factory hook.
- Create a fresh run hub in `configure_run` before constructing consumers.
- Define teardown: stop producers, dispose subscriptions/bridges, deactivate
  old run signals, then construct the replacement run.
- Define a committed run-ready notification after required setup.
- Decide precise readiness ordering relative to rule initialization,
  initial spawning, Mode initialization, and presentation snapshots.

### 2. Consolidate existing run notifications

- Move lifecycle and cycle signals off World/Graph to RunEvents.
- Update Naub, GraphWiring, Scoring, DebugMode, and Audio wiring.
- Preserve current event timing and cycle/scoring/destruction order.
- Preserve run-local references in delayed callbacks.
- Do not simultaneously change join ID ownership.

### 3. Remove presentation traversal

- Publish score updates, including initial/reset/absent values.
- Give basket notifications presentation payloads.
- Move Overlay/Background subscription ownership to their appropriate
  presentation owners.
- Replace Menu's Game traversal with a committed state payload.
- Replace finish callbacks with captured result notifications if useful.
- Remove Game's direct dependency on Naubino.audio.

### 4. Introduce simulation command boundaries

- Start with collision observation and loss requests.
- Decide whether policy returns a decision or emits commands. Either can
  preserve ownership; do not change it solely for stylistic consistency.
- Centralize join/split/replace execution before changing their transport.
- Keep collision-triggered operations queued until after physics stepping.
- Decide explicitly how synchronous factory joins use the same operation.
- Move interaction-release and destruction requests where they remove
  concrete cross-component dependencies.

### 5. Decouple Graph from Naub

- Decide whether Graph remains called internally by the join owner or
  becomes a topology projection.
- If projecting, move join ID allocation to the operation owner.
- Introduce structural join-added/removed payloads independent of sound.
- Remove Naub's Graph reference only once no remaining operation needs it.
- Evaluate cycles at committed topology boundaries.

### 6. Consolidate optional application notifications

- Unify theme and effects updates.
- Integrate settings notifications if it reduces duplicate mechanisms.
- Add layout/menu/mode commands only where they remove useful coupling.
- Remove unused signals after confirming no intended consumer needs them.

## Behavior checks

Follow `src/AGENTS.md`: do not write or modify tests. Use existing
validation, read-only/in-memory probes where useful, and browser checks.

Build validation:

- `deno task check`
- `deno task build`
- `deno task lint`, reporting unrelated existing failures separately

Runtime checks:

- Ordinary joins, rejected joins, and replacement still work.
- Collision mutations happen after physics stepping.
- Silent factory joins appear in Graph without unwanted feedback.
- Constraint handles, partner maps, graph edges, and drawing state agree.
- Replacement cycle detection never observes half-rewired topology.
- Scoring and chain bonuses retain their ordering and values.
- Destruction-start and actual-removal semantics remain distinct.
- Restart during destruction animations cannot affect the new run.
- Pause/resume preserves run events and elapsed-time behavior.
- Restart replaces run subscriptions without duplicating application ones.
- Mode switch while playing, paused, and stopped tears down old handlers.
- StandardMode-to-DebugMode clears score and basket presentation.
- DebugMode gestures never keep spawning into an old or inactive run.
- Audio does not double-play or react to stale-run callbacks.
- Initial presentation is correct even when buttons are built after rules.
- Final results refer to the completed run, not the replacement run.
- Stop cancellation, loss presentation, fullscreen, and layout still work.
- Application disposal removes persistent listeners and cancels owned work.

## Decisions still needed at implementation time

1. Exact command and notification names, including whether to rename the
   current destruction event to describe its actual timing.
2. Whether policy emits join/replace commands or keeps its decision return.
3. Whether Graph becomes a topology projection, and who allocates join IDs.
4. How synchronous factory operations share collision-driven commands
   without inheriting their deferred execution.
5. Whether Audio reconnects to each run hub or consumes persistent feedback.
6. Which outward payloads describe modes without exposing rule objects.
7. The exact committed run-ready boundary and initial-snapshot order.

No implementation step should depend on subscriber registration order to
make a multi-part mutation correct. Keep that transaction in one owner,
then publish its committed result.
