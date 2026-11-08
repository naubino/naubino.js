import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Session } from "../src/Session";

const events = {
  default: [
    { name: "init", from: ["none", "stopped"], to: "stopped" },
    { name: "play", from: ["paused", "stopped"], to: "playing" },
    { name: "pause", from: ["paused", "playing"], to: "paused" },
    { name: "stop", from: "*", to: "stopped" },
  ],
  game: [
    { name: "loose", from: "playing", to: "lost" },
    { name: "stop", from: "lost", to: "stopped" },
  ],
};

const lifecycleEvents = ["init", "play", "pause", "stop", "loose"];

const makeLayer = (
  name: string,
  calls: string[],
  layerEvents = events.default,
  fields: Record<string, unknown> = {},
) => {
  const layer: any = { name, ...fields };
  for (const event of lifecycleEvents) {
    layer[`on${event}`] = () => calls.push(`${name} ${event}`);
  }
  StateMachine.create({ target: layer, initial: "none", events: layerEvents });
  return layer;
};

const makeSession = ({
  snapshot = { name: "nobody", points: 10, time: 12, naubs: 4, game_version: 2, level: 3 },
  confirmStop = true,
} = {}) => {
  const calls: string[] = [];
  const on_finished = vi.fn(() => calls.push("finished"));
  const game = makeLayer("game", calls, events.default.concat(events.game), {
    confirm: vi.fn(() => confirmStop),
    score_snapshot: vi.fn(() => {
      calls.push("game snapshot");
      return snapshot;
    }),
    one_after_another: vi.fn((each: unknown, done: () => void) => {
      calls.push("game grey out");
      done();
    }),
    fade_out: vi.fn((done: () => void) => {
      calls.push("game fade out");
      done();
    }),
  });
  game.onbeforestop = (_event: string, _from: string, _to: string, force: boolean) =>
    force || game.confirm();

  const overlay = makeLayer("overlay", calls, undefined, {
    warning: (text: string) => calls.push(`overlay warning ${text}`),
  });
  const background = makeLayer("background", calls);
  const menu = {
    init: () => calls.push("menu init"),
    play: () => calls.push("menu play"),
    check_game_state: (checked: unknown) =>
      calls.push(checked === game ? "menu check" : "menu check other"),
  };
  const session = new Session({
    game,
    overlay,
    background,
    menu,
    events,
    on_finished,
  });

  return { session, calls, game, overlay, background, menu, on_finished, snapshot };
};

const makePlayingSession = (options = {}) => {
  const rig = makeSession(options);
  rig.session.init();
  rig.session.play();
  rig.calls.length = 0;
  return rig;
};

beforeEach(() => {
  vi.spyOn(console, "info").mockImplementation(() => {});
  vi.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => {
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

describe("startup", () => {
  it("inits game, overlay and background twice, the menu once", () => {
    const { session, calls, on_finished } = makeSession();

    session.init();

    expect(calls).toEqual([
      "game init",
      "overlay init",
      "background init",
      "menu check",
      "background init",
      "game init",
      "menu init",
      "overlay init",
    ]);
    expect(session.current).toBe("stopped");
    expect(on_finished).not.toHaveBeenCalled();
  });

  it("does not depend on a global app or prompt", () => {
    vi.stubGlobal("Naubino", undefined);
    vi.stubGlobal("prompt", vi.fn(() => {
      throw new Error("Session must not prompt");
    }));
    const { session } = makeSession();

    expect(() => session.init()).not.toThrow();
  });
});

describe("play and pause", () => {
  it("plays the menu first, then game, overlay and background", () => {
    const { session, calls } = makeSession();
    session.init();
    calls.length = 0;

    session.play();

    expect(calls).toEqual([
      "menu play",
      "game play",
      "overlay play",
      "background play",
      "menu check",
    ]);
    expect(session.current).toBe("playing");
  });

  it("pauses game, overlay and background", () => {
    const { session, calls } = makePlayingSession();

    session.pause();

    expect(calls).toEqual([
      "game pause",
      "overlay pause",
      "background pause",
      "menu check",
    ]);
    expect(session.current).toBe("paused");
  });

  it.each(["game", "overlay", "background"])("refuses to pause when %s cannot", (name) => {
    const rig = makePlayingSession();
    rig[name].stop();
    rig.calls.length = 0;

    rig.session.pause();

    expect(rig.calls).toEqual([]);
    expect(rig.session.current).toBe("playing");
  });

  it("toggles stopped to playing to paused to playing", () => {
    const { session } = makeSession();
    session.init();

    session.toggle();
    expect(session.current).toBe("playing");
    session.toggle();
    expect(session.current).toBe("paused");
    session.toggle();
    expect(session.current).toBe("playing");
  });
});

describe("stop", () => {
  it("captures a completed run before stopping and reports it after reset", () => {
    const { session, calls, game, on_finished, snapshot } = makePlayingSession();

    session.stop();

    expect(game.confirm).toHaveBeenCalledTimes(1);
    expect(calls).toEqual([
      "game snapshot",
      "game stop",
      "overlay stop",
      "background stop",
      "game init",
      "overlay init",
      "background init",
      "menu check",
      "finished",
    ]);
    expect(session.current).toBe("stopped");
    expect(on_finished).toHaveBeenCalledTimes(1);
    expect(on_finished).toHaveBeenCalledWith(snapshot);
  });

  it("discards the snapshot and stays playing when stop is declined", () => {
    const { session, calls, game, on_finished } = makePlayingSession({ confirmStop: false });

    session.stop();

    expect(calls).toEqual(["game snapshot"]);
    expect(game.current).toBe("playing");
    expect(session.current).toBe("playing");
    expect(on_finished).not.toHaveBeenCalled();
  });

  it("reports a zero-point snapshot", () => {
    const snapshot = { name: "nobody", points: 0, time: 0, naubs: 0, game_version: 2, level: 0 };
    const { session, on_finished } = makePlayingSession({ snapshot });

    session.stop();

    expect(on_finished).toHaveBeenCalledWith(snapshot);
  });

  it("passes force directly to the game and skips its confirm", () => {
    const { session, game } = makePlayingSession();

    session.stop(true);

    expect(game.confirm).not.toHaveBeenCalled();
    expect(game.current).toBe("stopped");
  });

  it("does not create a completion when stopping while already stopped", () => {
    const { session, calls, game, on_finished } = makeSession();
    session.init();
    calls.length = 0;

    session.stop();

    expect(game.confirm).toHaveBeenCalledTimes(1);
    expect(calls).toEqual(["game stop", "overlay stop", "background stop"]);
    expect(on_finished).not.toHaveBeenCalled();
  });
});

describe("loose", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  it("loses, warns, fades, then force-stops and reports the completion", () => {
    const { session, calls, game, on_finished, snapshot } = makePlayingSession();

    session.loose("Naub Overflow");

    expect(game.current).toBe("lost");
    expect(session.current).toBe("lost");
    expect(calls).toEqual([
      "game loose",
      "overlay warning Naub Overflow",
      "game grey out",
      "overlay stop",
      "background stop",
      "game fade out",
    ]);

    calls.length = 0;
    vi.advanceTimersByTime(2000);

    expect(game.confirm).not.toHaveBeenCalled();
    expect(session.current).toBe("stopped");
    expect(calls).toEqual([
      "game snapshot",
      "game stop",
      "overlay stop",
      "background stop",
      "game init",
      "overlay init",
      "background init",
      "menu check",
      "finished",
    ]);
    expect(on_finished).toHaveBeenCalledWith(snapshot);
  });

  it("warns with Game Over by default", () => {
    const { session, calls } = makePlayingSession();

    session.loose();

    expect(calls).toContain("overlay warning Game Over");
  });

  it("does not lose the game again when the game lost first", () => {
    const { session, calls, game } = makePlayingSession();
    game.loose();
    calls.length = 0;

    session.loose("Naub Overflow");

    expect(calls[0]).toBe("overlay warning Naub Overflow");
    expect(calls).not.toContain("game loose");
  });
});
