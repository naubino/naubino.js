# Round composition

Status: design exploration and rationale. Agreed decisions from the subsequent
design discussion are recorded in [design.md](design.md), which is the source of
truth for the target architecture and implementation stages.

That plan now supersedes the earlier Stage 5 split between game subclasses and
data-only modes. The exploration and original open questions below are retained
for context; some have since been resolved in design.md. Exact assembly APIs,
state ownership, activation timing, scheduling, and result identity remain open.

## Motivation

The current split leaves two awkward boundaries:

- `StandardGame` chooses the exact rule implementations, while `StandardMode`
  supplies their data. Changing the composition still requires another game
  implementation or changes to the existing subclass.
- Rules receive the entire game through `@game`. Their real dependencies are
  obscured by access to the round's state, infrastructure, and other rules.

Configuration has a similar problem. `Game.build_config` merges application
settings with mode overrides and knows about nested physics settings such as
`center_join`. The round host is interpreting configuration that belongs to its
individual consumers.

Separating behavior from data is useful, but it does not answer all three design
questions:

1. **Composition:** Which behaviors participate in a round?
2. **Configuration:** What parameters do those behaviors use?
3. **Access:** What state and operations may each behavior use?

## Proposed model

**A mode assembles a round. A game owns and runs it. Rules implement behavior.**

| Concept | Responsibility | Boundary |
|---|---|---|
| Mode | A round composition recipe: chooses implementations, supplies parameters, and connects dependencies and execution order. | Does not receive ongoing play, pause, or disposal callbacks. |
| Game / round | Owns the assembled instances and simulation infrastructure; advances the lifecycle and disposes the round. | Does not hardcode the standard gameplay composition. |
| Rule | Implements a behavior and owns its local runtime state. | Receives the dependencies it needs, not unrestricted access to the game. |
| Configuration | Describes initial parameters and progression data. | Is not mutated as the round progresses. |
| Settings | Holds application preferences such as audio, theme, and graphics. | Is not the catch-all source of gameplay tuning. |

"Game" is the current code name for the running round. Whether to rename it is
not decided here.

```mermaid
flowchart TD
    Selection[Select a mode] --> Mode[Mode composition recipe]
    Mode --> Choices[Choose behaviors and parameters]
    Choices --> Assembly[Connect dependencies and execution order]
    Assembly --> Round[Game owns the assembled round]
    Round --> Infrastructure[Simulation infrastructure]
    Round --> Rules[Live rule instances]
    Round --> Lifecycle[Play, pause, advance, dispose]
    Lifecycle --> Rules
```

The mode may bring factories or construction code. That is intentionally more
powerful than a data-only preset. The restriction is about lifetime and ownership:
construction belongs to the recipe; ongoing behavior belongs to the objects it
constructs.

This is not a return to `mode.playing(game)`, `mode.stop(game)`, or a reusable mode
object carrying timers between rounds. The exact construction API is still open.

## ECS influence, without committing to ECS

ECS separates composition, data access, and execution scheduling. Those are useful
ideas here even if Naubino never adopts an ECS library or storage model.

| Typical ECS concept | Approximate Naubino analogue |
|---|---|
| Entity | A naub's identity |
| Component | Data such as position, color, or join membership |
| System | A behavior such as spawning, scoring, or overflow checking |
| Resource | Round-wide state such as score, basket capacity, or elapsed time |
| Schedule | Lifecycle phases and execution order |
| Plugin or application assembly | A composition recipe that installs behaviors |

Rules are closest to systems, not entities or components. Depending on the ECS,
systems can also have local state.

ECS does not make gameplay dependencies disappear. It can make reads, writes,
and ordering constraints explicit and sometimes enforce them. A system with
unrestricted access to a world can be just as coupled as a rule with unrestricted
access to `@game`.

The proposal does not require component storage, a query engine, an ECS package,
or converting every field into a component.

## Composition belongs at construction

A standard composition currently needs basket geometry, spawning, scoring,
overflow checking, and level progression. A playground needs different behavior,
such as initial population and gesture-driven spawning.

The composition recipe should select and connect those behaviors. The game host
should not need to know which combination means "standard" or "playground".

A new mode could reuse a composition with different tuning, choose an alternative
implementation of a behavior, or assemble a different composition. How much of
that freedom we need remains an open question.

If `StandardGame` exists only to construct standard rules, this model removes its
reason to exist. A game subclass would need a separate justification: a genuine
difference in the round host rather than a different list of behaviors.

We should not replace explicit assembly with a generic rule registry or dependency
injection framework by default. Ordinary construction and direct dependency wiring
may be sufficient.

## Dependencies should describe the behavior

The target is not "every rule is independent". Some behaviors inherently depend on
others or on shared domain state.

For example:

- Overflow reads basket occupancy, publishes a warning, and requests a loss.
- Scoring consumes destruction and cycle results and updates score.
- Levels reads progression and changes spawn parameters and basket capacity.

```mermaid
flowchart TD
    Progress[Round progression] --> Levels[Levels behavior]
    LevelData[Configured progression table] --> Levels
    Levels --> SpawnState[Live spawn parameters]
    Levels --> Basket[Live basket capacity and occupancy]
    SpawnState --> Spawner[Spawner behavior]
    Basket --> Overflow[Overflow behavior]
    Overflow --> Warning[Overflow warning notification]
    Overflow --> Loss[Loss request to round lifecycle]
```

These are conceptual dependencies, not proposed class or signal definitions.
Whether basket capacity belongs to a rule, a shared resource, or a separate domain
object is not settled.

Passing a spawner control interface and basket access to `Levels` can accurately
express its dependencies. Passing the whole game grants much more access than it
needs.

Likewise, replacing `@game.basket` with `resources.get('basket')` is not necessarily
an improvement. A generic service locator can hide the same coupling behind a
lookup. Prefer concrete dependencies until evidence calls for something broader.

## Configuration follows ownership

The mode supplies parameters; the consuming component understands them and owns
its defaults. The game host should not know how to merge nested spring settings
or interpret spawn probabilities.

Keep the distinction between three kinds of values:

- **Application preferences:** audio, theme, graphics, and other page-level choices.
- **Round configuration:** the selected composition's initial tuning and progression
  tables, including explicit simulation or factory options where needed.
- **Runtime state:** current level, score, timers, effective spawn parameters, and
  current basket capacity.

Not everything is a rule. Physics and factory configuration should not be forced
into a `rules` section just to make the data look uniform. Ownership should guide
those boundaries instead of a catch-all `game_config` object.

For level progression, the mode supplies the table, `Levels` owns the current
level, and live spawning and basket state change during play. The table itself
must not become mutable round state.

Each round gets fresh mutable state, even when multiple rounds reuse the same
recipe and configuration. Initial parameters must be established before behavior
such as the first spawn runs. Constructor side effects and initialization order
need explicit consideration in the eventual construction API.

## Ordering is part of the gameplay

The current overflow-before-level-up order is meaningful: a level increase can
expand the basket, which changes the result of an overflow check.

```mermaid
flowchart TD
    Begin[Recurring check begins] --> Overflow[Check overflow using current capacity]
    Overflow --> Levels[Evaluate level progression]
    Levels --> Apply[Apply any new spawn parameters and basket capacity]
    Apply --> End[Check completes]
```

This diagram illustrates one existing ordering constraint, not a complete schedule
or a decision about what happens after a loss request.

The composition must make necessary ordering intentional. Whether that means an
explicit ordered list, a small set of phases, or scheduling constraints is open.
A general-purpose scheduler is not a prerequisite.

Events remain useful for reporting committed outcomes. They should not conceal
multi-part mutations or make correctness depend on subscriber order. Direct calls
between an owner and its explicit dependencies remain appropriate.

ECS command buffers are also relevant: deferring structural mutations can keep
entity creation and destruction safe while systems iterate. That is a separate
concern from mode composition. This proposal does not yet require a command buffer
or change the planned ownership of join operations in `World`.

## Lifecycle and disposal

The running game remains the lifetime boundary:

- Every round owns its live rules and any other constructed round resources.
- The game drives the supported rule lifecycle consistently.
- Play and pause do not reconstruct the composition.
- Restart constructs a fresh round from the selected recipe and configuration.
- Disposal stops timers, removes subscriptions, and prevents late work from
  affecting either the old round or its replacement.

Allowing factories must not weaken those guarantees. Assembly needs a clear way
to transfer ownership of created instances and cleanup work to the game. The
interface for doing that is still to be designed.

## Open questions

1. **Required flexibility:** Should a mode assemble arbitrary behaviors, or select
   among a few supported compositions with configurable implementations?
2. **Recipe versus preset:** Can one mode concept cover both composition and
   tuning clearly, or should reusable compositions have separately named presets?
3. **Assembly API:** What does a recipe receive, what does it return, and how does
   the host own everything without exposing the whole game?
4. **Rule access:** Which dependencies should be concrete objects, narrow control
   interfaces, or shared round state? Which current `@game` accesses are actually
   necessary?
5. **Shared domain state:** Who owns score, progression, basket capacity, and spawn
   parameters when multiple behaviors need them?
6. **Initialization:** How do we establish dependencies and initial configuration
   before constructors or startup hooks trigger visible behavior?
7. **Scheduling:** Is an ordered rule list sufficient? How should a loss request
   affect the remaining work in the current check?
8. **Lifecycle contract:** What lifecycle and cleanup operations do rules need,
   and how are non-rule resources included in round disposal?
9. **Identity and results:** Does a result identify the mode, composition version,
   tuning version, or some combination? Who defines its snapshot format?
10. **Debug behavior:** Which playground behaviors warrant rules, and does any
    remaining difference actually justify a `DebugGame` subclass?

## Next design step

Trace one standard round and one playground round through construction, first
spawn, play, pause, finish, and disposal. Use those concrete examples to identify
the smallest assembly contract and the actual dependencies of each behavior.

Choose the required composition flexibility before designing generic factories,
registries, resource containers, or scheduling machinery. Update the implementation
plan only after those boundaries are agreed.

---

## Design discussion: 2026-11-16

The following records decisions and interface sketches from the follow-up
conversation. It supplements the exploration above without rewriting it or
updating the implementation plan.

### Composition and mode identity

Modes may assemble different behaviors through ordinary construction and explicit
dependency wiring, within a common round lifecycle. They are not restricted to a
closed set of supported compositions. This does not require a registry,
dependency-injection framework, or general-purpose scheduler.

Mode remains the single selectable concept, covering both composition and tuning.
Slightly different mode implementations may hardcode different configurations.
Shared assembly helpers are optional; separate Composition and Preset concepts
are not needed.

Required variation includes debug auto joining, rounds with walls, and naubs
attached to screen-edge anchor points. These choices extend beyond selecting an
ordered list of gameplay rules.

### Infrastructure and assembly

Game generally constructs the common infrastructure before mode assembly. The
naub factory is an exception: the mode may construct and supply it, then inject
it into the rules that need it.

The proposed construction boundary has two steps:

1. Obtain the mode's current infrastructure configuration and construct the
   common infrastructure, including World. Game forwards physics options; the
   physics implementation owns its defaults and configuration merging.
2. Invoke mode assembly with explicit dependencies. The mode constructs its
   factory, rules, and other round resources and wires them together.

The recipe should not receive the whole Game. Construction access can be broader
than any individual rule's access: the recipe needs enough dependencies to wire
objects together, while each rule receives only what it uses. The exact assembly
arguments, returned ownership structure, and cleanup registration remain open.

### Configuration between rounds

Mode configuration may change between rounds without recreating the mode.
Each new round snapshots the current configuration, including copies of nested
values, before constructing its instances. Changes to the mode's configuration
do not affect an already constructed round.

The distinction is:

- Mode configuration is editable between rounds.
- Round configuration is the fixed snapshot used for that round.
- Runtime state belongs to the live objects and may change during play.

### Construction is distinct from activation

Construction, dependency wiring, and initial configuration must finish before
any gameplay behavior runs. A constructor or factory must not spawn naubs or
start running timers. In particular, the current Spawner constructor's initial
spawn must not precede the initial level configuration.

Rules need not be classes instantiated with `new`. A factory function may create
an object and configure it further before returning it. The host operates on the
returned Rule contract, regardless of how the object was produced. Individual
factories must not activate their own results.

Activation is a separate, once-per-round stage. Starting or resuming ongoing
behavior is distinct from activation and must not repeat initial population.
Whether activation happens immediately after assembly or on first play was not
yet decided; first play was recommended.

### What counts as a Rule

Rule is the name for a gameplay behavior driven by the round lifecycle. There
are no separate OneShotRule or InputDrivenRule types. Initial population can be
a Rule that only performs work during activation. Gesture spawning is a Rule
that responds repeatedly to input while playing.

| Concept | Examples | Responsibility |
|---|---|---|
| Rule | Spawner, Scoring, Overflow, Levels, initial population, gesture spawning | Gameplay behavior and local runtime state |
| Mode | Standard, Playground | Configuration, construction, and dependency wiring |
| Simulation infrastructure | World, PhysicsWorld, Graph | Object storage, physics, connectivity, and simulation operations |
| Factory | Naub factory | Creates configured naubs and groups when called |
| Policy | JoinPolicy | Makes decisions when invoked rather than running independently |
| Domain object or state | Basket, score state, attachment constraints | Domain data and operations used by rules |
| Presentation and input infrastructure | Layers, viewport, DragSystem | Rendering and interaction mechanisms |
| Round host | Game | Ownership and lifecycle of the assembled round |

Walls and attachments are physical structures, not inherently rules. A Rule is
appropriate if gameplay actively changes them. Basket can remain a domain object
shared by Levels and Overflow. Configurability alone does not make a policy or
factory a Rule, and requiring cleanup does not make a resource a Rule either.
The exact ownership of shared domain state remains unresolved.

The working TypeScript sketch uses optional hooks so a Rule implements only the
operations it needs:

```typescript
interface Rule {
  activate?(): void;
  start?(): void;
  stop?(): void;
  check?(): void;
  dispose?(): void;
}
```

The proposed meanings are:

- `activate`: once, after the entire composition and initial configuration are
  ready; may perform initial gameplay effects.
- `start`: begin or resume ongoing behavior.
- `stop`: suspend ongoing behavior without resetting its state.
- `check`: participate in the recurring gameplay check when implemented.
- `dispose`: permanently release resources, including when activation never ran.

Game invokes supported hooks and guarantees once-only activation. The sketch is
not yet a complete contract for hook ordering, transition failures, or cleanup
of non-rule resources.

### Input signals and subscriptions

Application input infrastructure defines and emits physical input signals. Game
makes the input source available to mode assembly. The mode decides which inputs
drive which rules and injects only the signals and operations each Rule needs.

For example, `gestureStarted` and `gestureEnded` are local dependency names, not
new signals defined by Game:

```typescript
const gestureSpawning = createGestureSpawning({
  gestureStarted: input.two_finger_start,
  gestureEnded: input.two_finger_end,
  spawnPair: () => factory.create_naub_pair(),
});
```

Game does not need to know that a two-finger gesture means spawning. The Rule
owns its subscriptions and any spawning timer. The proposed pattern is to
subscribe in `start`, unsubscribe and stop the timer in `stop`, and defensively
clean up in `dispose`. This keeps paused and finished rounds from responding to
input without requiring lifecycle checks in every handler. This pattern assumes
Game does not call `start` again without an intervening `stop`.

### Gameplay examples that informed the boundaries

Debug auto joining disables the dragging/focus requirement and the minimum
collision-force requirement. The remaining join behavior already works and is
not being redesigned here. These differences can be join-policy configuration;
replacement tie-breaking is outside this composition discussion.

Edge-attached naubs are ordinary playable naubs tethered to edge anchor points,
not special boundary entities. Edge tethering may coexist with center attraction.
An edge tether lasts for the naub's lifetime and is cleaned up when that naub is
destroyed. These requirements motivate configurable physical setup without
turning every attachment into a Rule.

### Questions still to answer

1. **Assembly API and ownership:** What exact dependencies does assembly receive,
   what does it return, and how does it transfer ownership of rules, factories,
   subscriptions, and other resources to Game without exposing the whole host?
2. **Rule dependencies:** For each existing Rule, which concrete objects, narrow
   operations, or shared state should replace its current `@game` accesses?
3. **Shared domain state:** Who owns score, elapsed time, destruction progress,
   basket capacity, and live spawn parameters, and how do their consumers access
   or change them?
4. **Activation timing and ordering:** Does activation occur on first play or
   immediately after assembly? In what order do rules activate, and how are all
   initial progression values established before any activation effects?
5. **Scheduling and transitions:** Is an ordered rule list sufficient? Does a
   loss request stop the remaining checks or other lifecycle work immediately?
6. **Lifecycle and cleanup contract:** Are the optional hooks above sufficient?
   What ordering and repetition guarantees apply, how are partial assembly or
   activation failures cleaned up, and how are non-rule resources disposed?
7. **Identity and results:** Does a result identify the mode, composition version,
   tuning version, or some combination? Who defines the result snapshot format
   when configuration can change between rounds?
8. **Host versus debug behavior:** After extracting playground population,
   gesture spawning, and mode-specific setup, does any genuine host difference
   still justify a DebugGame subclass?
9. **Concrete lifecycle traces:** Do standard and playground rounds both fit
   this boundary through construction, activation, first spawn, play, pause,
   finish, and disposal without introducing further host special cases?
