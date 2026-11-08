import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Game } from "../src/game/Game";
import { Scoring } from "../src/modes/standard/Scoring";
import { Overflow } from "../src/modes/standard/Overflow";
import { Levels } from "../src/modes/standard/Levels";
import { StandardMode } from "../src/modes/standard/StandardMode";
import { Basket } from "../src/modes/standard/Basket";
import { Background } from "../src/ui/Background";
import { Events } from "../src/Events";

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
  delete Naubino.game;
  vi.restoreAllMocks();
  vi.useRealTimers();
});

const makeScoring = (fields: Record<string, unknown> = {}) =>
  new Scoring({ points: 0, ex_naubs: 0, basket: { max_naubs: 20 }, ...fields });

const cycleOf = (length: number) =>
  Array.from({ length }, (_unused, index) => index + 1);

describe("Scoring calculate_points", () => {
  it("counts every naub of the cycle as destroyed", () => {
    const scoring = makeScoring({ ex_naubs: 7 });

    scoring.calculate_points(cycleOf(3));

    expect(scoring.game.ex_naubs).toBe(10);
  });

  it("adds floor((3 - 1) / max_naubs * length^2) points", () => {
    const scoring = makeScoring({ basket: { max_naubs: 20 }, points: 4 });

    scoring.calculate_points(cycleOf(5)); // 2 / 20 * 25 = 2.5

    expect(scoring.game.points).toBe(6);
  });

  it("gets cheaper with a bigger basket", () => {
    const scoring = makeScoring({ basket: { max_naubs: 50 } });

    scoring.calculate_points(cycleOf(10)); // 2 / 50 * 100 = 4

    expect(scoring.game.points).toBe(4);
  });

  // quirk: the bonus is floored, a triangle in a 20 naub basket gets 0.9 so nothing
  it("gives no bonus for small cycles", () => {
    const scoring = makeScoring({ basket: { max_naubs: 20 } });

    scoring.calculate_points(cycleOf(3));

    expect(scoring.game.points).toBe(0);
  });
});

describe("Scoring init", () => {
  const makeInitScoring = () =>
    new Scoring({
      naub_destroyed: { add: vi.fn() },
      cycle_found: { add: vi.fn() },
      basket: { max_naubs: 20 },
      points: 99,
      ex_naubs: 99,
      naubs_count: 99,
      get_object: (id: number) => ({ number: id, points_on_destroy: () => 1 }),
    });

  it("resets the counters on the game", () => {
    const scoring = makeInitScoring();

    scoring.init();

    expect(scoring.game.points).toBe(0);
    expect(scoring.game.ex_naubs).toBe(0);
    expect(scoring.game.naubs_count).toBe(0);
  });

  it("adds a destroyed naub's points_on_destroy to the points", () => {
    const scoring = makeInitScoring();
    scoring.init();
    const onDestroyed = scoring.game.naub_destroyed.add.mock.calls[0][0];

    onDestroyed(4);
    onDestroyed(5);

    expect(scoring.game.points).toBe(2);
  });

  it("scores a found cycle through calculate_points", () => {
    const scoring = makeInitScoring();
    scoring.init();
    const onCycle = scoring.game.cycle_found.add.mock.calls[0][0];

    onCycle(cycleOf(5));

    expect(scoring.game.ex_naubs).toBe(5);
    expect(scoring.game.points).toBe(2);
  });
});

describe("Scoring check", () => {
  it("stores the time since begin_time without writing through the global app", () => {
    vi.useFakeTimers();
    vi.setSystemTime(5000);
    const scoring = new Scoring({ begin_time: 1000 });

    scoring.check();

    expect(scoring.game.duration).toBe(4000);
    expect(Naubino.set_score).not.toHaveBeenCalled();
  });
});

const makeOverflow = (capacity: number) => {
  const events = new Events();
  vi.spyOn(events.game.overflow_warning, "dispatch");
  return new Overflow({
    basket: { capacity: vi.fn(() => capacity) },
    loose: vi.fn(),
    events,
  });
};

describe("Overflow warning", () => {
  it("warns with severity 0 when there is plenty of room", () => {
    const overflow = makeOverflow(100);

    overflow.check();

    expect(overflow.game.events.game.overflow_warning.dispatch).toHaveBeenCalledWith(0);
  });

  it("warns with (45 - capacity) / 45 below 45% capacity", () => {
    const overflow = makeOverflow(30);

    overflow.check();

    expect(overflow.game.events.game.overflow_warning.dispatch).toHaveBeenCalledWith(
      15 / 45,
    );
  });

  it("warns with severity 0 at exactly 45%", () => {
    const overflow = makeOverflow(45);

    overflow.check();

    expect(overflow.game.events.game.overflow_warning.dispatch).toHaveBeenCalledWith(0);
  });

  it("does not warn or lose when the mode has no basket", () => {
    const overflow = new Overflow({ events: new Events() });

    expect(() => overflow.check()).not.toThrow();
  });

  it("does not touch the background directly", () => {
    const overflow = makeOverflow(30);

    overflow.check();

    expect(Naubino.background.pulse).not.toHaveBeenCalled();
    expect(Naubino.background.stop_pulse).not.toHaveBeenCalled();
  });
});

// skips the constructor, only the pulse state matters
const makeBackground = (pulsating: boolean) =>
  Object.assign(Object.create(Background.prototype), {
    pulsating,
    pulse_speed: 10,
    pulse: vi.fn(),
    stop_pulse: vi.fn(),
  });

describe("Background warn_overflow", () => {
  it("stays calm at severity 0", () => {
    const background = makeBackground(false);

    background.warn_overflow(0);

    expect(background.pulse).not.toHaveBeenCalled();
    expect(background.stop_pulse).not.toHaveBeenCalled();
    expect(background.pulse_speed).toBe(10);
  });

  it("starts pulsing and scales the speed from 3 to 25 by severity", () => {
    const background = makeBackground(false);

    background.warn_overflow(1 / 3);

    expect(background.pulse).toHaveBeenCalledTimes(1);
    expect(background.pulse_speed).toBeCloseTo(3 + 22 / 3);
  });

  it("does not restart a pulse that is already running", () => {
    const background = makeBackground(true);

    background.warn_overflow(0.5);

    expect(background.pulse).not.toHaveBeenCalled();
    expect(background.pulse_speed).toBeCloseTo(14);
  });

  it("stops pulsing when the severity drops back to 0", () => {
    const background = makeBackground(true);

    background.warn_overflow(0);

    expect(background.stop_pulse).toHaveBeenCalledTimes(1);
  });
});

describe("Background basket geometry", () => {
  it("draws only when an optional geometry provider supplies a basket", () => {
    const calls: unknown[][] = [];
    const background = Object.assign(Object.create(Background.prototype), {
      center: () => ({ x: 100, y: 120 }),
      basket_size_provider: null,
      basket_thickness: 4,
      color: [10, 20, 30, 1],
      ctx: {
        save: vi.fn(), beginPath: vi.fn(), arc: (...args: unknown[]) => calls.push(args),
        stroke: vi.fn(), closePath: vi.fn(), restore: vi.fn(),
      },
    });
    Object.defineProperty(Naubino, "game", { configurable: true, get: () => { throw new Error("global game read"); } });

    expect(() => background.draw_basket()).not.toThrow();
    expect(calls).toHaveLength(0);

    background.basket_size_provider = () => 150;
    background.draw_basket();
    expect(calls[0][2]).toBe(158);
  });
});

describe("Standard basket", () => {
  it("owns capacity, count, and geometry outside the generic game", () => {
    const naub = { physical_body: { p: new cp.v(100, 100) }, size: 42 };
    const game = {
      objects: { 1: naub },
      center: () => new cp.v(100, 100),
    };
    const basket = new Basket(game, 20);

    expect(basket.count(0)).toEqual([naub]);
    expect(basket.basket_size()).toBeCloseTo(Math.sqrt(20 * 21 * 21 / 0.62));
    expect(basket.capacity()).toBe(95);
  });
});

describe("Overflow losing", () => {
  it("loses below 5% capacity", () => {
    const overflow = makeOverflow(4);

    overflow.check();

    expect(overflow.game.loose).toHaveBeenCalledWith("Naub Overflow");
  });

  it("does not lose at exactly 5%", () => {
    const overflow = makeOverflow(5);

    overflow.check();

    expect(overflow.game.loose).not.toHaveBeenCalled();
  });
});

describe("Game check", () => {
  it("runs every rule's check in list order", () => {
    const calls: string[] = [];
    const makeRule = (name: string) => ({ check: () => calls.push(name) });
    const game = Object.assign(Object.create(Game.prototype), {
      rules: [makeRule("first"), makeRule("second")],
    });

    game.check();

    expect(calls).toEqual(["first", "second"]);
  });

  // a level up grows the basket, must not run before the lose check
  // same order as StandardMode.rules
  it("checks for losing before leveling up when Overflow comes before Levels", () => {
    const calls: string[] = [];
    const game = {
      basket: { capacity: () => 4 },
      loose: vi.fn(() => calls.push("loose")),
      begin_time: 0,
      ex_naubs: 0,
      events: { game: { overflow_warning: { dispatch: vi.fn() } } },
    };
    const levels = new Levels(game, {}, StandardMode.prototype.level_details);
    levels.level = 0;
    levels.load_level = vi.fn(() => calls.push("level up"));
    const runner = Object.assign(Object.create(Game.prototype), {
      rules: [new Scoring(game), new Overflow(game), levels],
    });

    runner.check();

    expect(calls).toEqual(["loose", "level up"]);
  });
});
