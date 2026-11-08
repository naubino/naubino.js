import { afterEach, describe, expect, it, vi } from "vitest";
import { Naubino as Application } from "../src/Naubino";
import { Events } from "../src/Events";
import { StandardMode } from "../src/modes/standard/StandardMode";

const makeApplication = () => Object.create(Application.prototype);
const touch = (clientX: number, clientY: number) => ({ clientX, clientY });

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("Naubino composition", () => {
  it("forwards public lifecycle commands to its session", () => {
    const app = makeApplication();
    app.session = Object.fromEntries(
      ["init", "play", "pause", "stop", "loose", "toggle", "can"].map((name) => [name, vi.fn(() => true)]),
    );

    app.init();
    app.play();
    app.pause();
    app.stop(true);
    app.loose("overflow");
    app.toggle();
    expect(app.can("play")).toBe(true);

    expect(app.session.init).toHaveBeenCalledOnce();
    expect(app.session.play).toHaveBeenCalledOnce();
    expect(app.session.pause).toHaveBeenCalledOnce();
    expect(app.session.stop).toHaveBeenCalledWith(true);
    expect(app.session.loose).toHaveBeenCalledWith("overflow");
    expect(app.session.toggle).toHaveBeenCalledOnce();
    expect(app.session.can).toHaveBeenCalledWith("play");
  });

  it("auto-starts the selected mode only after session initialization", () => {
    const app = makeApplication();
    const calls: string[] = [];
    app.mode = { auto_start: true };
    app.setup_dom = () => calls.push("dom");
    app.setup_components = () => calls.push("components");
    app.setup_session = () => calls.push("session");
    app.setup_input = () => calls.push("input");
    app.init = () => calls.push("init");
    app.play = () => calls.push("play");
    app.start_loop = () => calls.push("loop");
    vi.spyOn(console, "timeEnd").mockImplementation(() => {});

    app.setup();

    expect(calls).toEqual(["dom", "components", "session", "input", "init", "play", "loop"]);
  });

  it("delegates field resizing to the viewport", () => {
    const app = makeApplication();
    app.viewport = { resize_field: vi.fn() };

    app.resize_field(640, 480);

    expect(app.viewport.resize_field).toHaveBeenCalledWith(640, 480);
  });

  it("wires Input to the application event hub without canvas aliases or callbacks", () => {
    const app = makeApplication();
    const canvasListeners: Record<string, (event: any) => void> = {};
    const keyListeners: Record<string, (event: any) => void> = {};
    const canvas = {
      addEventListener: vi.fn((name, listener) => { canvasListeners[name] = listener; }),
      removeEventListener: vi.fn(),
    };
    vi.stubGlobal("window", {
      addEventListener: vi.fn((name, listener) => { keyListeners[name] = listener; }),
      removeEventListener: vi.fn(),
    });
    app.events = new Events();
    app.viewport = {
      canvases: { overlay_canvas: canvas },
      to_local: vi.fn(() => ({ x: 20, y: 30 })),
    };
    const pointerStart = vi.fn();
    const toggle = vi.fn();
    const stop = vi.fn();
    app.events.input.pointer_start.add(pointerStart);
    app.events.commands.toggle.add(toggle);
    app.events.commands.stop.add(stop);

    app.setup_input();
    canvasListeners.mousedown({ clientX: 100, clientY: 200 });
    keyListeners.keydown({ which: 32 });
    keyListeners.keydown({ which: 27 });

    expect(pointerStart).toHaveBeenCalledWith(20, 30);
    expect(app.viewport.to_local).toHaveBeenCalledWith(100, 200, canvas);
    expect(toggle).toHaveBeenCalledOnce();
    expect(stop).toHaveBeenCalledOnce();
    expect(app.mousedown).toBeUndefined();
    expect(app.canvases).toBeUndefined();
    expect(app.overlay_canvas).toBeUndefined();
    app.input.unbind();
  });

  it("routes an actual standard two-finger tap from app Input through the hub command", () => {
    const app = makeApplication();
    const canvasListeners: Record<string, (event: any) => void> = {};
    const keyboard = { addEventListener: vi.fn(), removeEventListener: vi.fn() };
    const canvas = {
      addEventListener: vi.fn((name, listener) => { canvasListeners[name] = listener; }),
      removeEventListener: vi.fn(),
    };
    vi.stubGlobal("window", keyboard);
    app.events = new Events();
    app.viewport = {
      canvases: { overlay_canvas: canvas },
      to_local: vi.fn(() => ({ x: 20, y: 30 })),
    };
    const toggle = vi.fn();
    app.events.commands.toggle.add(toggle);
    const unbindMode = new StandardMode().bind({}, app.events);

    app.setup_input();
    const touchEvent = (type: string, count: number) => ({
      type,
      changedTouches: [touch(10, 20)],
      touches: Array.from({ length: count }, (_unused, index) => touch(index + 10, index + 20)),
      preventDefault: vi.fn(),
    });
    canvasListeners.touchstart(touchEvent("touchstart", 1));
    canvasListeners.touchstart(touchEvent("touchstart", 2));
    canvasListeners.touchend(touchEvent("touchend", 1));
    canvasListeners.touchend(touchEvent("touchend", 0));

    expect(toggle).toHaveBeenCalledOnce();
    unbindMode();
    app.input.unbind();
  });

  it("keeps the finished score snapshot while prompting and storing", () => {
    const app = makeApplication();
    const score = { points: 42, level: 3 };
    app.store_score = vi.fn();
    vi.stubGlobal("prompt", vi.fn(() => "hendrik"));

    app.finish_run(score);

    expect(app.temp_score).toBe(score);
    expect(app.store_score).toHaveBeenCalledWith("hendrik");
  });

  it("does not prompt for zero points or store a cancelled score", () => {
    const app = makeApplication();
    app.store_score = vi.fn();
    vi.stubGlobal("prompt", vi.fn(() => null));

    app.finish_run({ points: 0 });
    expect(prompt).not.toHaveBeenCalled();
    app.finish_run({ points: 42 });
    expect(prompt).toHaveBeenCalledOnce();
    expect(app.store_score).not.toHaveBeenCalled();
  });
});
