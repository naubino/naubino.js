import { afterEach, describe, expect, it, vi } from "vitest";
import { Naubino as Application } from "../src/Naubino";

const makeApplication = () => Object.create(Application.prototype);

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

  it("delegates field resizing to the viewport", () => {
    const app = makeApplication();
    app.viewport = { resize_field: vi.fn() };

    app.resize_field(640, 480);

    expect(app.viewport.resize_field).toHaveBeenCalledWith(640, 480);
  });

  it("wires input signals and session commands without copying canvas aliases", () => {
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
    app.viewport = {
      canvases: { overlay_canvas: canvas },
      to_local: vi.fn(() => ({ x: 20, y: 30 })),
    };
    app.mousedown = { dispatch: vi.fn() };
    app.mousemove = { dispatch: vi.fn() };
    app.mouseup = { dispatch: vi.fn() };
    app.session = { toggle: vi.fn(), stop: vi.fn() };

    app.setup_input();
    canvasListeners.mousedown({ clientX: 100, clientY: 200 });
    keyListeners.keydown({ which: 32 });
    keyListeners.keydown({ which: 27 });

    expect(app.mousedown.dispatch).toHaveBeenCalledWith(20, 30);
    expect(app.viewport.to_local).toHaveBeenCalledWith(100, 200, canvas);
    expect(app.session.toggle).toHaveBeenCalledOnce();
    expect(app.session.stop).toHaveBeenCalledOnce();
    expect(app.canvases).toBeUndefined();
    expect(app.overlay_canvas).toBeUndefined();
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
