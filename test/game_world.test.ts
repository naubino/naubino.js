import { afterEach, describe, expect, it, vi } from "vitest";
import { Game } from "../src/game/Game";
import { World } from "../src/game/World";
import { StandardMode } from "../src/modes/standard/StandardMode";
import { Factory } from "../src/game/Factory";
import { Events } from "../src/Events";

// skips the constructor, no canvas or fsm needed for the world plumbing
const makeGame = () =>
  Object.assign(Object.create(Game.prototype), {
    width: 400,
    height: 300,
    world: new World(400, 300),
    config: { physics: Naubino.settings.physics },
    graph: { clear: vi.fn() },
    center: () => new cp.Vect(200, 150),
  });

const makeNaub = () => {
  const body = new cp.Body(1, 1);
  const shape = new cp.CircleShape(body, 10, cp.vzero);
  return {
    physical_body: body,
    physical_shape: shape,
    constraints: [],
    attracted_to: vi.fn(),
  };
};

const expectExposed = (game: any) => {
  expect(game.objects).toBe(game.world.objects);
  expect(game.physics).toBe(game.world.physics);
  expect(game.space).toBe(game.world.physics.space);
  expect(game.mouseBody).toBe(game.world.physics.mouseBody);
  expect(game.GRABABLE_MASK_BIT).toBe(game.world.physics.GRABABLE_MASK_BIT);
  expect(game.naub_destroyed).toBe(game.world.naub_destroyed);
  expect(game.naub_focused).toBe(game.world.naub_focused);
  expect(game.naub_unfocused).toBe(game.world.naub_unfocused);
};

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

const makeDestroyBatchGame = (entities: Record<number, any>) =>
  Object.assign(Object.create(Game.prototype), {
    destroy_batches: [],
    destroying_naubs: {},
    get_object: (id: number) => entities[id],
  });

const makeDestroyable = () => ({ disable: vi.fn(), destroy: vi.fn(), removed: false });

describe("Game destroy batches", () => {
  it("runs overlapping batches independently and drains their timers", () => {
    vi.useFakeTimers();
    const entities = { 1: makeDestroyable(), 2: makeDestroyable(), 3: makeDestroyable(), 4: makeDestroyable() };
    const game = makeDestroyBatchGame(entities);

    game.destroy_naubs([1, 2]);
    game.destroy_naubs([3, 4]);
    expect(game.destroy_batches).toHaveLength(2);
    vi.advanceTimersByTime(120);

    for (const entity of Object.values(entities)) expect(entity.destroy).toHaveBeenCalledOnce();
    expect(game.destroy_batches).toHaveLength(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it("destroys shared entities only once across overlapping batches", () => {
    vi.useFakeTimers();
    const entities = { 1: makeDestroyable(), 2: makeDestroyable(), 3: makeDestroyable() };
    const game = makeDestroyBatchGame(entities);

    game.destroy_naubs([1, 2]);
    game.destroy_naubs([2, 3]);
    vi.advanceTimersByTime(120);

    expect(entities[1].destroy).toHaveBeenCalledOnce();
    expect(entities[2].destroy).toHaveBeenCalledOnce();
    expect(entities[3].destroy).toHaveBeenCalledOnce();
    expect(vi.getTimerCount()).toBe(0);
  });

  it("skips entities removed before their batch reaches them", () => {
    vi.useFakeTimers();
    const entities: Record<number, any> = { 1: makeDestroyable(), 2: makeDestroyable() };
    const game = makeDestroyBatchGame(entities);

    game.destroy_naubs([1, 2]);
    delete entities[2];
    expect(() => vi.advanceTimersByTime(120)).not.toThrow();
    expect(game.destroy_batches).toHaveLength(0);
    expect(vi.getTimerCount()).toBe(0);
  });

  it.each(["reset", "stop", "dispose"])("cancels all pending batches on %s", (lifecycle) => {
    vi.useFakeTimers();
    const entities = { 1: makeDestroyable(), 2: makeDestroyable(), 3: makeDestroyable(), 4: makeDestroyable() };
    const game: any = makeDestroyBatchGame(entities);
    game.destroy_naubs([1, 2]);
    game.destroy_naubs([3, 4]);

    if (lifecycle === "reset") {
      Object.assign(game, {
        mode: { init: vi.fn() }, rules: [], world: { reset_signals: vi.fn() }, space: {},
        setup_physics: vi.fn(),
      });
      vi.spyOn(console, "log").mockImplementation(() => {});
      game.oninit();
    } else if (lifecycle === "stop") {
      game.clear_objects = vi.fn();
      game.onstopped("stop");
    } else {
      Object.assign(game, {
        mode: {}, rules: [], stop_stepping: vi.fn(), stop_drawing: vi.fn(),
      });
      game.dispose();
    }

    expect(game.destroy_batches).toHaveLength(0);
    expect(vi.getTimerCount()).toBe(0);
    vi.advanceTimersByTime(1200);
    expect(entities[2].destroy).not.toHaveBeenCalled();
    expect(entities[4].destroy).not.toHaveBeenCalled();
  });
});

describe("Game world plumbing", () => {
  it("resizes the field and updates each naub's center and spring anchor", () => {
    const game = makeGame();
    game.center = () => new cp.Vect(game.width / 2, game.height / 2);
    const naub: any = { constraints: { center: { anchr2: new cp.Vect(200, 150) } } };
    const unanchored: any = {};
    game.for_each = (visit: (naub: any) => void) => [naub, unanchored].forEach(visit);

    game.resize(800, 600);

    expect(game.width).toBe(800);
    expect(game.height).toBe(600);
    expect(naub.center).toEqual(new cp.Vect(400, 300));
    expect(naub.constraints.center.anchr2).toEqual(new cp.Vect(400, 300));
    expect(naub.constraints.center.anchr2).not.toBe(naub.center);
    expect(unanchored.center).toEqual(new cp.Vect(400, 300));
  });

  it("captures a score independently of subsequent game resets", () => {
    const game = makeGame();
    game.mode = new StandardMode();
    Object.assign(game, { points: 42, duration: 1200, ex_naubs: 8, version: 2, levels: { level: 3 } });
    const score = game.score_snapshot();
    game.points = 0;
    game.levels.level = 0;

    expect(score).toEqual({ name: "nobody", points: 42, time: 1200, naubs: 8, game_version: 2, level: 3, mode: "standard" });
  });
  it("uses the local creation offset for factory spawns", () => {
    const layer = { width: 400, height: 300, config: { game: { creation_offset: -200 } } };
    const factory = new Factory(layer);
    const random = vi.spyOn(Math, "random").mockReturnValue(0);

    const position = factory.random_outside();

    expect(position.x).toBe(200);
    expect(position.y).toBe(0);
    random.mockRestore();
  });

  it("delegates score snapshots to the active mode", () => {
    const mode = { result: vi.fn(() => null) };
    const game = Object.assign(Object.create(Game.prototype), { mode });

    expect(game.score_snapshot()).toBeNull();
    expect(mode.result).toHaveBeenCalledWith(game);
  });

  it("returns null for an unranked mode result", () => {
    const game = Object.assign(Object.create(Game.prototype), { mode: { result: () => null } });

    expect(game.score_snapshot()).toBeNull();
  });

  it("emits generic loss reasons through its event hub without reaching through the app global", () => {
    const events = new Events();
    const outcome = vi.fn();
    const stop_stepping = vi.fn();
    events.game.outcome.add(outcome);
    const game = Object.assign(Object.create(Game.prototype), { events, stop_stepping });

    game.onloose("loose", "playing", "lost", "test outcome");

    expect(stop_stepping).toHaveBeenCalledOnce();
    expect(outcome).toHaveBeenCalledWith("test outcome");
  });

  it("keeps mode gameplay overrides local to the game", () => {
    const defaults = { ...Naubino.settings.game };
    const game = Object.assign(Object.create(Game.prototype), {
      mode: { game_config: { creation_offset: -200, min_joining_force: 10 }, physics_config: { damping: 0.5 } },
    });

    game.config = game.build_config();

    expect(game.config.game.creation_offset).toBe(-200);
    expect(game.config.game.min_joining_force).toBe(10);
    expect(game.config.physics.damping).toBe(0.5);
    expect(Naubino.settings.game).toEqual(defaults);
  });

  it("disposes its single mode binding and mode resources", () => {
    const unbindMode = vi.fn();
    const disposeMode = vi.fn();
    const game = Object.assign(Object.create(Game.prototype), {
      mode_unsubscribe: unbindMode,
      destroy_batches: [],
      mode: { dispose: disposeMode },
      rules: [],
      stop_stepping: vi.fn(),
      stop_drawing: vi.fn(),
    });

    game.dispose();

    expect(unbindMode).toHaveBeenCalledOnce();
    expect(disposeMode).toHaveBeenCalledWith(game);
  });

  it("binds input and mode subscriptions once in the constructor and releases both on dispose", () => {
    vi.spyOn(console, "log").mockImplementation(() => {});
    const events = new Events();
    const unbindMode = vi.fn();
    const mode = {
      id: "probe",
      version: 0,
      game_config: {},
      physics_config: {},
      join_policy: vi.fn(() => ({})),
      rules: vi.fn(() => []),
      bind: vi.fn(() => unbindMode),
      reset: vi.fn(),
      init: vi.fn(),
      stop: vi.fn(),
      dispose: vi.fn(),
      confirm_stop: vi.fn(() => true),
      result: vi.fn(() => null),
    };
    const canvas = { width: 400, height: 300, style: {}, getContext: vi.fn(() => ({})) };
    const game = new Game(canvas, mode, events);
    const startDrag = vi.spyOn(game.drag, "start");

    game.init();
    game.init();
    events.input.pointer_start.dispatch(20, 30);

    expect(mode.bind).toHaveBeenCalledOnce();
    expect(startDrag).toHaveBeenCalledOnce();

    game.dispose();
    events.input.pointer_start.dispatch(40, 50);

    expect(unbindMode).toHaveBeenCalledOnce();
    expect(mode.dispose).toHaveBeenCalledWith(game);
    expect(startDrag).toHaveBeenCalledOnce();
  });

  it("has no generic basket API", () => {
    expect(Game.prototype.basket_size).toBeUndefined();
    expect(Game.prototype.capacity).toBeUndefined();
  });

  it("expose_world copies the world's live references onto the game", () => {
    const game = makeGame();
    game.expose_world();
    expectExposed(game);
  });

  it("setup_physics swaps in a fresh space and re-exposes it", () => {
    const game = makeGame();
    game.expose_world();
    const oldSpace = game.space;
    game.setup_physics();
    expect(game.space).not.toBe(oldSpace);
    expectExposed(game);
  });

  it("clear_objects empties the world, re-exposes it and clears the graph", () => {
    const game = makeGame();
    game.expose_world();
    game.add_object(makeNaub());
    const oldSpace = game.space;

    game.clear_objects();

    expect(game.objects).toEqual({});
    expect(game.space).not.toBe(oldSpace);
    expect(game.graph.clear).toHaveBeenCalled();
    expectExposed(game);
  });

  it("add_object registers the naub, tags body and shape, and attracts it to the center", () => {
    const game = makeGame();
    game.expose_world();
    const naub = makeNaub();

    game.add_object(naub);

    expect(game.get_object(1)).toBe(naub);
    expect(naub.physical_body.naub_number).toBe(1);
    expect(naub.physical_shape.naub_number).toBe(1);
    expect(naub.attracted_to).toHaveBeenCalled();
    expect(game.space.containsBody(naub.physical_body)).toBe(true);
  });

  it("remove_obj takes the naub out of the world", () => {
    const game = makeGame();
    game.expose_world();
    const naub = makeNaub();
    game.add_object(naub);

    game.remove_obj(1);

    expect(game.get_object(1)).toBeUndefined();
    expect(game.space.containsBody(naub.physical_body)).toBe(false);
  });
});
