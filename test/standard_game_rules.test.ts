import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Game } from "../src/game/Game";
import { World } from "../src/game/World";
import { Mode } from "../src/modes/Mode";
import { StandardMode } from "../src/modes/standard/StandardMode";
import { DebugMode } from "../src/modes/DebugMode";
import { Scoring } from "../src/modes/standard/Scoring";
import { Overflow } from "../src/modes/standard/Overflow";
import { Rule } from "../src/modes/Rule";
import { Spawner } from "../src/modes/standard/Spawner";
import { Levels } from "../src/modes/standard/Levels";

const makeSpammer = (probability: number) => ({
  probability,
  method: vi.fn(),
});

const makeSpammers = () => ({
  pair: makeSpammer(5),
  mixed_1: makeSpammer(0),
  mixed_2: makeSpammer(0),
  triple: makeSpammer(0),
});

// fields by hand, no game needed
const makeSpawner = (fields: Record<string, unknown> = {}) =>
  Object.assign(
    new Spawner({}),
    {
      number_of_colors: 3,
      spammer_interval: 40,
      inner_clock: 0,
      spammers: makeSpammers(),
    },
    fields,
  );

// the real table StandardMode hands to Levels
const levelDetails = StandardMode.prototype.level_details;

const makeLevelRig = (level = 0, spammers = makeSpammers()) => {
  const game = { max_naubs: 20, basket_changed: { dispatch: vi.fn() } };
  const spawner = { number_of_colors: 3, spammer_interval: 40, spammers };
  const levels = new Levels(game, spawner, levelDetails);
  levels.level = level;
  return { game, spawner, levels };
};

beforeEach(() => {
  Naubino.background = {
    draw: vi.fn(),
    pulsating: false,
    pulse: vi.fn(),
    stop_pulse: vi.fn(),
  };
  Naubino.set_score = vi.fn();
});

afterEach(() => {
  delete Naubino.background;
  delete Naubino.set_score;
  vi.restoreAllMocks();
});

describe("Spawner max_color", () => {
  it("returns a color index below number_of_colors", () => {
    vi.spyOn(Math, "random").mockReturnValue(0.999);
    const spawner = makeSpawner({ number_of_colors: 7 });

    expect(spawner.max_color()).toBe(6);
  });

  it("scales Math.random by number_of_colors and floors it", () => {
    vi.spyOn(Math, "random").mockReturnValue(0.5);
    const spawner = makeSpawner({ number_of_colors: 4 });

    expect(spawner.max_color()).toBe(2);
  });

  it("returns 0 when Math.random returns 0", () => {
    vi.spyOn(Math, "random").mockReturnValue(0);
    const spawner = makeSpawner({ number_of_colors: 5 });

    expect(spawner.max_color()).toBe(0);
  });
});

describe("Spawner map_spammers", () => {
  it("maps spammers to cumulative ranges in key order", () => {
    const pairMethod = vi.fn();
    const mixedMethod = vi.fn();
    const tripleMethod = vi.fn();
    const spawner = makeSpawner({
      spammers: {
        pair: { probability: 5, method: pairMethod },
        mixed_1: { probability: 0, method: mixedMethod },
        triple: { probability: 3, method: tripleMethod },
      },
    });

    expect(spawner.map_spammers()).toEqual([
      { range: 5, name: "pair", method: pairMethod },
      { range: 5, name: "mixed_1", method: mixedMethod },
      { range: 8, name: "triple", method: tripleMethod },
    ]);
  });
});

describe("Spawner spam", () => {
  const makeSpamSpawner = () =>
    makeSpawner({
      spammers: {
        pair: makeSpammer(5),
        mixed_1: makeSpammer(0),
        triple: makeSpammer(3),
      },
    });

  it.each([
    { roll: 0, expected: "pair" },
    { roll: 0.6, expected: "pair" },
    { roll: 0.625, expected: "triple" },
    { roll: 0.99, expected: "triple" },
  ])("picks $expected for a roll of $roll", ({ roll, expected }) => {
    vi.spyOn(Math, "random").mockReturnValue(roll);
    const spawner = makeSpamSpawner();

    spawner.spam();

    for (const name of ["pair", "mixed_1", "triple"]) {
      const expectedCalls = name === expected ? 1 : 0;
      expect(spawner.spammers[name].method).toHaveBeenCalledTimes(expectedCalls);
    }
  });

  it("never calls a zero-probability spammer", () => {
    vi.spyOn(Math, "random").mockReturnValue(0);
    const spawner = makeSpamSpawner();

    spawner.spam();

    expect(spawner.spammers.mixed_1.method).not.toHaveBeenCalled();
  });

  // quirk: all probabilities 0 means dart 0 and no range above it, spawns nothing
  it("spawns nothing when all probabilities are 0", () => {
    vi.spyOn(Math, "random").mockReturnValue(0.5);
    const spawner = makeSpawner({
      spammers: {
        pair: makeSpammer(0),
        mixed_1: makeSpammer(0),
        triple: makeSpammer(0),
      },
    });

    expect(() => spawner.spam()).not.toThrow();
    expect(spawner.spammers.pair.method).not.toHaveBeenCalled();
    expect(spawner.spammers.mixed_1.method).not.toHaveBeenCalled();
    expect(spawner.spammers.triple.method).not.toHaveBeenCalled();
  });

  // quirk: reduce without an initial value, an empty spammer map throws
  it("throws a TypeError when there are no spammers at all", () => {
    const spawner = makeSpawner({ spammers: {} });

    expect(() => spawner.spam()).toThrow(TypeError);
  });
});

describe("Spawner event", () => {
  const makeEventSpawner = (fields: Record<string, unknown> = {}) =>
    makeSpawner({ spam: vi.fn(), spammer_interval: 3, inner_clock: 0, ...fields });

  // quirk: the first tick spams right away, not after one spammer_interval
  it("spams on the first tick and returns spammer_interval", () => {
    const spawner = makeEventSpawner();

    const result = spawner.event();

    expect(spawner.spam).toHaveBeenCalledTimes(1);
    expect(result).toBe(3);
    expect(spawner.inner_clock).toBe(1);
  });

  it("does not spam while inner_clock is not zero", () => {
    const spawner = makeEventSpawner({ inner_clock: 1 });

    spawner.event();

    expect(spawner.spam).not.toHaveBeenCalled();
    expect(spawner.inner_clock).toBe(2);
  });

  it("wraps inner_clock back to zero modulo spammer_interval", () => {
    const spawner = makeEventSpawner({ inner_clock: 2 });

    spawner.event();

    expect(spawner.spam).not.toHaveBeenCalled();
    expect(spawner.inner_clock).toBe(0);
  });

  it("spams exactly once per spammer_interval consecutive calls", () => {
    const spawner = makeEventSpawner();

    for (let index = 0; index < 9; index++) {
      spawner.event();
    }

    expect(spawner.spam).toHaveBeenCalledTimes(3);
  });
});

describe("Spawner init", () => {
  const makeInitSpawner = () => {
    const spawner = new Spawner({
      factory: { create_naub_pair: vi.fn(), create_naub_triple: vi.fn() },
    });
    spawner.init();
    return spawner;
  };

  it("sets the default color count and resets the clock", () => {
    const spawner = makeInitSpawner();

    expect(spawner.number_of_colors).toBe(3);
    expect(spawner.inner_clock).toBe(0);
  });

  it("creates the spammers with the level 0 probabilities", () => {
    const spawner = makeInitSpawner();

    expect(Object.keys(spawner.spammers)).toEqual([
      "pair",
      "mixed_1",
      "mixed_2",
      "triple",
    ]);
    expect(spawner.spammers.pair.probability).toBe(5);
    expect(spawner.spammers.mixed_1.probability).toBe(0);
    expect(spawner.spammers.mixed_2.probability).toBe(0);
    expect(spawner.spammers.triple.probability).toBe(0);
  });

  it("wires each spammer method to the matching factory call", () => {
    vi.spyOn(Math, "random").mockReturnValue(0.5);
    const spawner = makeInitSpawner();

    spawner.spammers.pair.method();
    spawner.spammers.mixed_1.method();
    spawner.spammers.mixed_2.method();
    spawner.spammers.triple.method();

    const factory = spawner.game.factory;
    expect(factory.create_naub_pair).toHaveBeenNthCalledWith(1, null, 1, 1);
    expect(factory.create_naub_pair).toHaveBeenNthCalledWith(2, null, 1, 1, 1);
    expect(factory.create_naub_pair).toHaveBeenNthCalledWith(3, null, 1, 1, 2);
    expect(factory.create_naub_triple).toHaveBeenCalledWith(null, 1, 1, 1);
  });
});

describe("Levels init", () => {
  it("loads level 0 into the spawner", () => {
    const spawner = new Spawner({ factory: {} });
    spawner.init();
    const game = { basket_changed: { dispatch: vi.fn() } };
    const levels = new Levels(game, spawner, levelDetails);

    levels.init();

    expect(levels.level).toBe(0);
    expect(spawner.spammer_interval).toBe(40);
    expect(spawner.spammers.pair.probability).toBe(5);
    expect(spawner.spammers.mixed_1.probability).toBe(0);
    expect(spawner.spammers.mixed_2.probability).toBe(0);
    expect(spawner.spammers.triple.probability).toBe(0);
    expect(game.basket_changed.dispatch).toHaveBeenCalledTimes(1);
  });
});

describe("Levels load_level", () => {
  it("applies the details of a level", () => {
    const { game, spawner, levels } = makeLevelRig();

    levels.load_level(3);

    expect(levels.level).toBe(3);
    expect(game.max_naubs).toBe(30);
    expect(spawner.number_of_colors).toBe(4);
    expect(spawner.spammer_interval).toBe(30);
    expect(spawner.spammers.pair.probability).toBe(9);
    expect(spawner.spammers.mixed_1.probability).toBe(0);
    expect(spawner.spammers.mixed_2.probability).toBe(0);
    expect(spawner.spammers.triple.probability).toBe(1);
    expect(game.basket_changed.dispatch).toHaveBeenCalledTimes(1);
  });

  it("does not load level 0 when going up", () => {
    const { spawner, levels } = makeLevelRig(1);
    const loadSpy = vi.spyOn(levels, "load_level");

    levels.load_level(2);

    expect(loadSpy.mock.calls).toEqual([[2]]);
    expect(levels.level).toBe(2);
    expect(spawner.spammers.pair.probability).toBe(9);
    expect(spawner.spammers.triple.probability).toBe(2);
  });

  it("loads level 0 first when going down", () => {
    const { game, spawner, levels } = makeLevelRig(3);
    const loadSpy = vi.spyOn(levels, "load_level");

    levels.load_level(1);

    // spy logs the outer call on entry, so [1] before the nested [0]
    expect(loadSpy.mock.calls).toEqual([[1], [0]]);
    expect(levels.level).toBe(1);
    expect(game.max_naubs).toBe(20);
    expect(spawner.number_of_colors).toBe(3);
    expect(spawner.spammer_interval).toBe(38);
    expect(spawner.spammers.pair.probability).toBe(1);
    expect(spawner.spammers.mixed_1.probability).toBe(0);
    expect(spawner.spammers.mixed_2.probability).toBe(0);
    expect(spawner.spammers.triple.probability).toBe(0);
  });

  // quirk: level 0 has no probabilities, the previous ones stay
  it("keeps spammer probabilities when loading level 0", () => {
    const { game, spawner, levels } = makeLevelRig(2, {
      pair: makeSpammer(9),
      mixed_1: makeSpammer(0),
      mixed_2: makeSpammer(0),
      triple: makeSpammer(2),
    });

    levels.load_level(0);

    expect(levels.level).toBe(0);
    expect(game.max_naubs).toBe(20);
    expect(spawner.spammer_interval).toBe(40);
    expect(spawner.spammers.pair.probability).toBe(9);
    expect(spawner.spammers.triple.probability).toBe(2);
  });

  // quirk: guard is >= not >, so length itself gets through and the lookup throws
  // level is already 15 by then, basket_changed never fires
  it("throws a TypeError for level_details.length and leaves level at that value", () => {
    const { game, levels } = makeLevelRig(0);
    const levelCount = levelDetails.length;

    expect(() => levels.load_level(levelCount)).toThrow(TypeError);
    expect(levels.level).toBe(levelCount);
    expect(game.basket_changed.dispatch).not.toHaveBeenCalled();
  });

  // quirk: levels above level_details.length are silently ignored
  it("ignores levels above level_details.length", () => {
    const { game, spawner, levels } = makeLevelRig(0);
    const levelCount = levelDetails.length;

    levels.load_level(levelCount + 1);

    expect(levels.level).toBe(0);
    expect(spawner.spammer_interval).toBe(40);
    expect(game.basket_changed.dispatch).not.toHaveBeenCalled();
  });
});

describe("Levels check", () => {
  const makeCheckLevels = (level: number, exNaubs: number) => {
    const levels = new Levels({ ex_naubs: exNaubs }, {}, levelDetails);
    levels.level = level;
    levels.load_level = vi.fn();
    return levels;
  };

  it("levels up when ex_naubs is above the level limit", () => {
    const levels = makeCheckLevels(1, 21);

    levels.check();

    expect(levels.load_level).toHaveBeenCalledWith(2);
  });

  it("does not level up when ex_naubs equals the level limit", () => {
    const levels = makeCheckLevels(1, 20);

    levels.check();

    expect(levels.load_level).not.toHaveBeenCalled();
  });

  // quirk: level 0 has limit -1, first tick goes to level 1 with nothing destroyed
  it("levels up from level 0 even with ex_naubs at 0", () => {
    const levels = makeCheckLevels(0, 0);

    levels.check();

    expect(levels.load_level).toHaveBeenCalledWith(1);
  });

  it("levels up by one level per call", () => {
    const levels = makeCheckLevels(1, 500);

    levels.check();

    expect(levels.load_level).toHaveBeenCalledTimes(1);
    expect(levels.load_level).toHaveBeenCalledWith(2);
  });
});

const makeSignalGame = () => ({
  naub_replaced: { add: vi.fn() },
  naub_destroyed: { add: vi.fn() },
  cycle_found: { add: vi.fn() },
  naub_focused: { add: vi.fn() },
});

describe("StandardMode", () => {

  it("builds spawner, scoring, overflow and levels in that order", () => {
    const game: any = {};

    const rules = new StandardMode().rules(game);

    expect(rules).toEqual([game.spawner, game.scoring, game.overflow, game.levels]);
    expect(game.spawner).toBeInstanceOf(Spawner);
    expect(game.scoring).toBeInstanceOf(Scoring);
    expect(game.overflow).toBeInstanceOf(Overflow);
    expect(game.levels).toBeInstanceOf(Levels);
    expect(game.levels.spawner).toBe(game.spawner);
    expect(game.levels.level_details).toBe(levelDetails);
  });

  // scoring listeners and counters are Scoring's
  it("wires the cycle reaction and the active tree", () => {
    const game = makeSignalGame();

    new StandardMode().init(game);

    expect(game.naub_replaced.add).toHaveBeenCalledTimes(1);
    expect(game.naub_destroyed.add).not.toHaveBeenCalled();
    expect(game.cycle_found.add).toHaveBeenCalledTimes(1);
    expect(game.naub_focused.add).toHaveBeenCalledTimes(1);
  });

  it("asks the user before stopping", () => {
    vi.stubGlobal("confirm", vi.fn(() => false));

    expect(new StandardMode().confirm_stop()).toBe(false);
    expect(confirm).toHaveBeenCalledTimes(1);
    vi.unstubAllGlobals();
  });

  it("is version 2", () => {
    expect(new StandardMode().version).toBe(2);
  });
});

describe("Mode defaults", () => {
  it("has no rules, version 0 and allows stopping", () => {
    const mode = new Mode();

    expect(mode.rules({})).toEqual([]);
    expect(mode.version).toBe(0);
    expect(mode.confirm_stop()).toBe(true);
    expect(mode.init({})).toBeUndefined();
    expect(mode.playing({}, "stopped")).toBeUndefined();
  });
});

describe("DebugMode", () => {
  const savedUpdating = Naubino.settings.graphics.updating;
  const savedOffset = Naubino.settings.game.creation_offset;

  afterEach(() => {
    Naubino.settings.graphics.updating = savedUpdating;
    Naubino.settings.game.creation_offset = savedOffset;
  });

  it("wires the cycle reaction, tweaks settings and auto plays after 300ms", () => {
    vi.useFakeTimers();
    Naubino.play = vi.fn();
    const game = makeSignalGame();

    new DebugMode().init(game);

    expect(game.naub_replaced.add).toHaveBeenCalledTimes(1);
    expect(game.cycle_found.add).toHaveBeenCalledTimes(1);
    expect(game.naub_focused.add).not.toHaveBeenCalled();
    expect(Naubino.settings.graphics.updating).toBe(false);
    expect(Naubino.settings.game.creation_offset).toBe(-200);
    vi.advanceTimersByTime(300);
    expect(Naubino.play).toHaveBeenCalledTimes(1);
    delete Naubino.play;
    vi.useRealTimers();
  });

  it("adds six balls and the matching pairs when starting from stopped", () => {
    const mode = new DebugMode();
    mode.add_ball = vi.fn();
    const game = { factory: { create_matching_naubs: vi.fn() } };

    mode.playing(game, "stopped");

    expect(game.factory.create_matching_naubs).toHaveBeenCalledTimes(1);
    expect(mode.add_ball).toHaveBeenCalledTimes(6);
    expect(mode.add_ball).toHaveBeenCalledWith(game);
  });

  // quirk: resuming from pause adds six more balls
  it("adds six more balls but no pairs when resuming from paused", () => {
    const mode = new DebugMode();
    mode.add_ball = vi.fn();
    const game = { factory: { create_matching_naubs: vi.fn() } };

    mode.playing(game, "paused");

    expect(game.factory.create_matching_naubs).not.toHaveBeenCalled();
    expect(mode.add_ball).toHaveBeenCalledTimes(6);
  });

  it("has no rules and never asks before stopping", () => {
    const mode = new DebugMode();

    expect(mode.rules({})).toEqual([]);
    expect(mode.confirm_stop()).toBe(true);
  });
});

describe("Game mode hooks", () => {
  const makeModeGame = (mode: any, rules: any[] = []) =>
    Object.assign(Object.create(Game.prototype), {
      width: 400,
      height: 300,
      world: new World(400, 300),
      rules,
      mode,
    });

  beforeEach(() => {
    vi.spyOn(console, "log").mockImplementation(() => {});
  });

  it("inits the rules, then the mode", () => {
    const calls: string[] = [];
    const rule = { init: () => calls.push("rule") };
    const mode = { init: vi.fn(() => calls.push("mode")) };
    const game = makeModeGame(mode, [rule]);

    game.oninit();

    expect(calls).toEqual(["rule", "mode"]);
    expect(mode.init).toHaveBeenCalledWith(game);
  });

  it("hands the previous state to the mode's playing hook", () => {
    vi.useFakeTimers();
    const mode = { playing: vi.fn() };
    const game = makeModeGame(mode);

    game.onplaying("play", "stopped", "playing");

    expect(mode.playing).toHaveBeenCalledWith(game, "stopped");
    game.onleaveplaying();
    vi.useRealTimers();
  });

  it("lets the mode confirm a stop", () => {
    const mode = { confirm_stop: vi.fn(() => false) };
    const game = makeModeGame(mode);

    expect(game.onbeforestop("stop", "playing", "stopped")).toBe(false);
    expect(mode.confirm_stop).toHaveBeenCalledTimes(1);
  });

  it("skips the confirm when force is passed directly", () => {
    const mode = { confirm_stop: vi.fn(() => false) };
    const game = makeModeGame(mode);

    expect(game.onbeforestop("stop", "playing", "stopped", true)).toBe(true);
    expect(mode.confirm_stop).not.toHaveBeenCalled();
  });
});

describe("onplaying and onleaveplaying", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  const makePlayingGame = () => {
    const spawner = new Spawner({});
    spawner.event = vi.fn();
    const game = Object.assign(Object.create(Game.prototype), {
      rules: [spawner],
      check: vi.fn(),
      mode: new Mode(),
    });
    return { game, spawner };
  };

  it("runs event every 100ms and check every 300ms", () => {
    const { game, spawner } = makePlayingGame();

    game.onplaying();
    vi.advanceTimersByTime(300);

    expect(spawner.event).toHaveBeenCalledTimes(3);
    expect(game.check).toHaveBeenCalledTimes(1);
  });

  it("does not start a second set of intervals when called again", () => {
    const { game, spawner } = makePlayingGame();

    game.onplaying();
    game.onplaying();
    vi.advanceTimersByTime(300);

    expect(spawner.event).toHaveBeenCalledTimes(3);
    expect(game.check).toHaveBeenCalledTimes(1);
  });

  it("stops both intervals and clears their handles", () => {
    const { game, spawner } = makePlayingGame();

    game.onplaying();
    vi.advanceTimersByTime(100);
    game.onleaveplaying();
    vi.advanceTimersByTime(1000);

    expect(spawner.spamming).toBeNull();
    expect(game.checking).toBeNull();
    expect(spawner.event).toHaveBeenCalledTimes(1);
    expect(game.check).not.toHaveBeenCalled();
  });
});

describe("Game rule hooks", () => {
  const makeHookRule = (name: string, calls: string[]) => ({
    init: vi.fn(),
    start: vi.fn(() => {
      calls.push(`${name} start`);
    }),
    stop: vi.fn(() => {
      calls.push(`${name} stop`);
    }),
  });

  const makeHookGame = (calls: string[]) =>
    Object.assign(Object.create(Game.prototype), {
      rules: [makeHookRule("a", calls), makeHookRule("b", calls)],
      mode: new Mode(),
    });

  // onplaying starts the check interval, keep it off the real clock
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("starts the rules in list order on playing", () => {
    const calls: string[] = [];
    const game = makeHookGame(calls);

    game.onplaying();

    expect(calls).toEqual(["a start", "b start"]);
  });

  it("stops the rules in list order on leaving playing", () => {
    const calls: string[] = [];
    const game = makeHookGame(calls);

    game.onleaveplaying();

    expect(calls).toEqual(["a stop", "b stop"]);
  });
});

describe("Rule", () => {
  it("keeps the game it was built with", () => {
    const game = {};

    expect(new Rule(game).game).toBe(game);
  });

  it("has hooks that do nothing", () => {
    const rule = new Rule({});

    expect(rule.init()).toBeUndefined();
    expect(rule.start()).toBeUndefined();
    expect(rule.stop()).toBeUndefined();
    expect(rule.check()).toBeUndefined();
  });
});

describe("Levels is generic", () => {
  // no built in table, another mode can bring its own progression
  it("uses whatever level_details it was constructed with", () => {
    const game = { max_naubs: 0, basket_changed: { dispatch: vi.fn() } };
    const spawner = { number_of_colors: 0, spammer_interval: 0, spammers: {} };
    const customLevelDetails = [
      { limit: -1, max_naubs: 5, number_of_colors: 1, interval: 1000 },
    ];
    const levels = new Levels(game, spawner, customLevelDetails);

    levels.init();

    expect(levels.level).toBe(0);
    expect(game.max_naubs).toBe(5);
    expect(spawner.number_of_colors).toBe(1);
    expect(spawner.spammer_interval).toBe(1000);
    expect(levels.level_details).toBe(customLevelDetails);
    expect(levels.level_details).not.toBe(levelDetails);
  });
});
