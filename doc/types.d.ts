// Shadow types for the target architecture in design.md.
// Not compiled or imported. CoffeeScript object literals and classes are
// expected to match these shapes until the TypeScript migration.
// Field names follow the CoffeeScript code (snake_case).

type Unsubscribe = () => void;

interface Vector {
  x: number;
  y: number;
}

interface Bounds {
  left: number;
  top: number;
  right: number;
  bottom: number;
}

interface Signal<Args extends unknown[] = []> {
  active: boolean;
  add(listener: (...args: Args) => void, abort_signal?: AbortSignal): Unsubscribe;
  dispatch(...args: Args): void;
}

interface Layer {
  readonly canvas: HTMLCanvasElement;
  readonly ctx: CanvasRenderingContext2D;
}

interface Naub {
  readonly number: number;
  color_id: number | null;
  points_on_destroy(): number;
}

interface World {
  get_object(id: number): Naub | undefined;
  naub_at(position: Vector): Naub | undefined;
  naubs(): Iterable<Naub>;
  join(first: Naub, second: Naub): number;
  replace(kept: Naub, removed: Naub): void;
  destroy_naubs(ids: readonly number[]): void;
}

interface Graph {
  add_join(id: number, first: number, second: number): void;
  remove_join(id: number): void;
  cycle_test(first?: number): number[][];
  tree(naub: number): number[];
  partners(naub: number, predecessor?: number): number[];
}

interface JoinPolicy {
  check_joining(first: Naub, second: Naub): JoinAction | null;
}

interface JoinAction {
  action: 'join' | 'replace';
  pair: [Naub, Naub];
}

type GameState = 'ready' | 'playing' | 'paused' | 'lost' | 'finished';

interface GameEvents {
  readonly loss_requested: Signal<[reason: string]>;

  readonly join_added: Signal<[id: number, first: number, second: number]>;
  readonly join_removed: Signal<[id: number]>;
  readonly naub_joined: Signal<[id: number]>;
  readonly naub_replaced: Signal<[id: number]>;
  readonly naub_destroyed: Signal<[id: number]>;
  readonly naub_focused: Signal<[naub: Naub]>;
  readonly cycle_found: Signal<[ids: number[]]>;

  readonly state_changed: Signal<[state: GameState]>;
  readonly score_changed: Signal<[points: number]>;
  readonly level_changed: Signal<[level: number]>;
  readonly chain_bonus: Signal<[points: number]>;
  readonly overflow_warning: Signal<[severity: number]>;

  readonly lost: Signal<[reason: string]>;
  readonly finished: Signal<[snapshot: ScoreSnapshot | null]>;
}

interface InputSignals {
  readonly two_finger_start: Signal;
  readonly two_finger_end: Signal;
  readonly two_finger_tap: Signal;
}

interface FieldGeometry {
  center(): Vector;
  view_bounds(): Bounds;
}

interface Rule {
  activate?(): void;
  start?(): void;
  stop?(): void;
  check?(): void;
  dispose?(): void;
}
// check() runs every 300 ms while playing, in AssembledRound.rules order.
// Game ends the pass once the round leaves playing. Return values are ignored.

type ModeConfig = Readonly<{ name?: string } & Record<string, unknown>>;

interface RoundContext {
  readonly config: ModeConfig;
  readonly world: World;
  readonly events: GameEvents;
  readonly input: InputSignals;
  readonly field: FieldGeometry;
  readonly layer: Layer;
  lease_layer(depth: number): Layer;
}

interface Progress {
  cleared_naubs(): number;
}

interface SpawnParameters {
  number_of_colors: number;
  interval: number;
}

interface Spawner extends Rule {
  configure(parameters: Partial<SpawnParameters>): void;
}

interface Basket {
  capacity(): number;
  max_naubs(): number;
  set_capacity(max_naubs: number): void;
}

interface Scoreboard {
  points: number;
  level: number;
}

interface RoundResult {
  points: number;
  time: number;
  naubs: number;
  level: number;
}

interface ScoreSnapshot extends RoundResult {
  name: string;
  mode: string;
  config_name?: string;
  game_version: string;
}

interface RoundResults {
  scoreboard(): Scoreboard;
  final(): RoundResult;
}

interface AssembledRound {
  readonly rules: readonly Rule[];
  readonly join_policy?: JoinPolicy;
  readonly results?: RoundResults;
}

interface Mode {
  configuration(): ModeConfig;
  assemble(context: RoundContext): AssembledRound;
}
