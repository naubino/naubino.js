import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Game } from "../src/Game";
import { Scoring } from "../src/rules/Scoring";
import { Overflow } from "../src/rules/Overflow";
import { Levels } from "../src/rules/Levels";
import { StandardGame } from "../src/StandardGame";

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
  vi.useRealTimers();
});

const makeScoring = (fields: Record<string, unknown> = {}) =>
  new Scoring({ points: 0, ex_naubs: 0, max_naubs: 20, ...fields });

const cycleOf = (length: number) =>
  Array.from({ length }, (_unused, index) => index + 1);

describe("Scoring calculate_points", () => {
  it("counts every naub of the cycle as destroyed", () => {
    const scoring = makeScoring({ ex_naubs: 7 });

    scoring.calculate_points(cycleOf(3));

    expect(scoring.game.ex_naubs).toBe(10);
  });

  it("adds floor((3 - 1) / max_naubs * length^2) points", () => {
    const scoring = makeScoring({ max_naubs: 20, points: 4 });

    scoring.calculate_points(cycleOf(5)); // 2 / 20 * 25 = 2.5

    expect(scoring.game.points).toBe(6);
  });

  it("gets cheaper with a bigger basket", () => {
    const scoring = makeScoring({ max_naubs: 50 });

    scoring.calculate_points(cycleOf(10)); // 2 / 50 * 100 = 4

    expect(scoring.game.points).toBe(4);
  });

  // quirk: the bonus is floored, a triangle in a 20 naub basket gets 0.9 so nothing
  it("gives no bonus for small cycles", () => {
    const scoring = makeScoring({ max_naubs: 20 });

    scoring.calculate_points(cycleOf(3));

    expect(scoring.game.points).toBe(0);
  });
});

describe("Scoring init", () => {
  const makeInitScoring = () =>
    new Scoring({
      naub_destroyed: { add: vi.fn() },
      cycle_found: { add: vi.fn() },
      max_naubs: 20,
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
  // quirk: begin_time is only set in the Game constructor
  // so duration counts from page load, not from game start
  it("stores the time since begin_time as duration and records the score", () => {
    vi.useFakeTimers();
    vi.setSystemTime(5000);
    const scoring = new Scoring({ begin_time: 1000 });

    scoring.check();

    expect(scoring.game.duration).toBe(4000);
    expect(Naubino.set_score).toHaveBeenCalledTimes(1);
  });
});

const makeOverflow = (capacity: number) =>
  new Overflow({ capacity: vi.fn(() => capacity), loose: vi.fn() });

describe("Overflow warning", () => {
  it("leaves the background alone with plenty of room", () => {
    const overflow = makeOverflow(100);

    overflow.check();

    expect(Naubino.background.pulse).not.toHaveBeenCalled();
    expect(Naubino.background.stop_pulse).not.toHaveBeenCalled();
    expect(Naubino.background.ttl).toBeUndefined();
  });

  it("starts pulsing below 45% capacity and scales ttl and speed", () => {
    const overflow = makeOverflow(30);

    overflow.check();

    expect(Naubino.background.pulse).toHaveBeenCalledTimes(1);
    expect(Naubino.background.ttl).toBe(15);
    // interpolate(3, 25, (45 - 30) / 45)
    expect(Naubino.background.pulse_speed).toBeCloseTo(3 + 22 / 3);
  });

  it("does not restart a pulse that is already running", () => {
    Naubino.background.pulsating = true;
    const overflow = makeOverflow(30);

    overflow.check();

    expect(Naubino.background.pulse).not.toHaveBeenCalled();
    expect(Naubino.background.ttl).toBe(15);
  });

  it("stops pulsing once capacity is back at 45%", () => {
    Naubino.background.pulsating = true;
    const overflow = makeOverflow(45);

    overflow.check();

    expect(Naubino.background.stop_pulse).toHaveBeenCalledTimes(1);
    expect(Naubino.background.ttl).toBe(45);
  });
});

describe("Overflow losing", () => {
  it("loses below 5% capacity", () => {
    const overflow = makeOverflow(4);

    overflow.check();

    expect(overflow.game.loose).toHaveBeenCalledTimes(1);
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
  // mirrors StandardGame's @rules order (the constructor needs a canvas)
  it("checks for losing before leveling up when Overflow comes before Levels", () => {
    const calls: string[] = [];
    const game = {
      capacity: () => 4,
      loose: vi.fn(() => calls.push("loose")),
      begin_time: 0,
      ex_naubs: 0,
    };
    const levels = new Levels(game, {}, StandardGame.prototype.level_details);
    levels.level = 0;
    levels.load_level = vi.fn(() => calls.push("level up"));
    const runner = Object.assign(Object.create(Game.prototype), {
      rules: [new Scoring(game), new Overflow(game), levels],
    });

    runner.check();

    expect(calls).toEqual(["loose", "level up"]);
  });
});
