import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { LayerManager } from "../src/LayerManager";

// pins the app lifecycle through Naubino's forwarding methods
// fake layers run real state machines with the real event tables and log every event

const gameEvents = () =>
  Naubino.settings.events.default.concat(Naubino.settings.events.game);

const lifecycleEvents = ["init", "play", "pause", "stop", "loose"];

const makeLayer = (
  name: string,
  calls: string[],
  events = Naubino.settings.events.default,
  fields: Record<string, unknown> = {},
) => {
  const layer: any = { name, ...fields };
  for (const event of lifecycleEvents) {
    layer[`on${event}`] = () => calls.push(`${name} ${event}`);
  }
  StateMachine.create({ target: layer, initial: "none", events });
  return layer;
};

// confirmStop plays the user answering StandardGame's stop confirm
const makeNaubino = ({ points = 10, confirmStop = true } = {}) => {
  const calls: string[] = [];
  const naubino: any = Object.create(LayerManager.prototype);
  const game = makeLayer("game", calls, gameEvents(), {
    confirm: vi.fn(() => confirmStop),
    one_after_another: vi.fn((each: unknown, done: () => void) => {
      calls.push("game grey out");
      done();
    }),
    fade_out: vi.fn((done: () => void) => {
      calls.push("game fade out");
      done();
    }),
  });
  // mirrors StandardGame.onbeforestop
  game.onbeforestop = () => {
    if (naubino.override) {
      delete naubino.override;
      return true;
    }
    return game.confirm();
  };
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
  const storeScore = vi.fn();
  Naubino.store_score = storeScore;
  Object.assign(naubino, {
    name: "Naubino",
    game,
    overlay,
    background,
    menu,
    layers: [background, game, menu, overlay],
    temp_score: { points },
    store_score: storeScore,
  });
  naubino.setup_session();
  return { naubino, calls, game, overlay, background };
};

// already playing, call log cleared
const makePlayingNaubino = (options = {}) => {
  const rig = makeNaubino(options);
  rig.naubino.init();
  rig.naubino.play();
  rig.calls.length = 0;
  return rig;
};

beforeEach(() => {
  vi.spyOn(console, "info").mockImplementation(() => {});
  vi.spyOn(console, "warn").mockImplementation(() => {});
  vi.spyOn(console, "error").mockImplementation(() => {});
  vi.stubGlobal("prompt", vi.fn(() => "hendrik"));
});

afterEach(() => {
  delete Naubino.store_score;
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  vi.useRealTimers();
});

describe("startup", () => {
  // quirk: onstopped inits game, overlay and background,
  // then oninit inits every layer again
  it("inits game, overlay and background twice, the menu once", () => {
    const { naubino, calls } = makeNaubino();

    naubino.init();

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
    expect(naubino.session.current).toBe("stopped");
  });

  it("does not ask for a highscore name", () => {
    const { naubino } = makeNaubino();

    naubino.init();

    expect(prompt).not.toHaveBeenCalled();
  });
});

describe("play and pause", () => {
  it("plays the menu first, then game, overlay and background", () => {
    const { naubino, calls } = makeNaubino();
    naubino.init();
    calls.length = 0;

    naubino.play();

    expect(calls).toEqual([
      "menu play",
      "game play",
      "overlay play",
      "background play",
      "menu check",
    ]);
    expect(naubino.session.current).toBe("playing");
  });

  it("pauses game, overlay and background", () => {
    const { naubino, calls } = makePlayingNaubino();

    naubino.pause();

    expect(calls).toEqual([
      "game pause",
      "overlay pause",
      "background pause",
      "menu check",
    ]);
    expect(naubino.session.current).toBe("paused");
  });

  it("refuses to pause when the game can't", () => {
    const { naubino, game, calls } = makePlayingNaubino();
    game.stop();
    calls.length = 0;

    naubino.pause();

    expect(calls).toEqual([]);
    expect(naubino.session.current).toBe("playing");
  });

  it("toggles stopped to playing to paused to playing", () => {
    const { naubino } = makeNaubino();
    naubino.init();

    naubino.toggle();
    expect(naubino.session.current).toBe("playing");
    naubino.toggle();
    expect(naubino.session.current).toBe("paused");
    naubino.toggle();
    expect(naubino.session.current).toBe("playing");
  });
});

describe("stop", () => {
  it("stops game, overlay and background, re-inits them and asks for a name", () => {
    const { naubino, calls, game } = makePlayingNaubino();

    naubino.stop();

    expect(game.confirm).toHaveBeenCalledTimes(1);
    expect(calls).toEqual([
      "game stop",
      "overlay stop",
      "background stop",
      "game init",
      "overlay init",
      "background init",
      "menu check",
    ]);
    expect(naubino.session.current).toBe("stopped");
    expect(prompt).toHaveBeenCalledTimes(1);
    expect(naubino.store_score).toHaveBeenCalledWith("hendrik");
  });

  it("stays playing when the game's confirm is declined", () => {
    const { naubino, calls, game } = makePlayingNaubino({ confirmStop: false });

    naubino.stop();

    expect(calls).toEqual([]);
    expect(game.current).toBe("playing");
    expect(naubino.session.current).toBe("playing");
  });

  it("does not ask for a name when no points were scored", () => {
    const { naubino } = makePlayingNaubino({ points: 0 });

    naubino.stop();

    expect(prompt).not.toHaveBeenCalled();
  });

  it("does not store a score when the name prompt is cancelled", () => {
    const { naubino } = makePlayingNaubino();
    vi.stubGlobal("prompt", vi.fn(() => null));

    naubino.stop();

    expect(naubino.store_score).not.toHaveBeenCalled();
  });

  it("passes stop(yes) to the game as an override that skips the confirm", () => {
    const { naubino, game } = makePlayingNaubino();

    naubino.stop(true);

    expect(game.confirm).not.toHaveBeenCalled();
    expect(game.current).toBe("stopped");
    expect(naubino.override).toBeUndefined();
  });

  it("leaves override false after a plain stop", () => {
    const { naubino } = makePlayingNaubino();

    naubino.stop();

    expect(naubino.override).toBe(false);
  });

  // quirk: stopping while stopped still asks the game's confirm
  // nothing re-inits, stopped -> stopped skips onstopped
  it("asks the game to confirm even when already stopped", () => {
    const { naubino, calls, game } = makeNaubino();
    naubino.init();
    calls.length = 0;

    naubino.stop();

    expect(game.confirm).toHaveBeenCalledTimes(1);
    expect(calls).toEqual(["game stop", "overlay stop", "background stop"]);
    expect(prompt).not.toHaveBeenCalled();
  });
});

describe("loose", () => {
  // losing schedules a stop 2s out, keep that off the real clock
  beforeEach(() => {
    vi.useFakeTimers();
  });

  it("loses the game too, warns, greys out, fades and stops two seconds later", () => {
    const { naubino, calls, game } = makePlayingNaubino();

    naubino.loose("Naub Overflow");

    expect(game.current).toBe("lost");
    expect(naubino.session.current).toBe("lost");
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
    expect(naubino.session.current).toBe("stopped");
    expect(calls).toEqual([
      "game stop",
      "overlay stop",
      "background stop",
      "game init",
      "overlay init",
      "background init",
      "menu check",
    ]);
    expect(prompt).toHaveBeenCalledTimes(1);
  });

  it("warns with Game Over by default", () => {
    const { naubino, calls } = makePlayingNaubino();

    naubino.loose();

    expect(calls).toContain("overlay warning Game Over");
  });

  it("does not lose the game again when the game lost first", () => {
    const { naubino, calls, game } = makePlayingNaubino();
    game.loose();
    calls.length = 0;

    naubino.loose("Naub Overflow");

    expect(calls[0]).toBe("overlay warning Naub Overflow");
    expect(calls).not.toContain("game loose");
  });
});
