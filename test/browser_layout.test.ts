import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  application: null as any,
  isFullscreen: false,
  isTouch: false,
  Naubino: vi.fn(function () {
    return mocks.application;
  }),
  toggleFullscreen: vi.fn(),
}));

vi.mock("../src/Naubino", () => ({ Naubino: mocks.Naubino }));
vi.mock("../src/core/Util", () => ({
  Util: {
    isFullscreen: () => mocks.isFullscreen,
    isTouch: () => mocks.isTouch,
    toggleFullscreen: mocks.toggleFullscreen,
  },
}));

type Listener = (this: any, event?: Event) => void;

const eventTarget = () => {
  const listeners = new Map<string, Listener[]>();

  return {
    addEventListener: vi.fn((type: string, listener: Listener) => {
      listeners.set(type, [...(listeners.get(type) ?? []), listener]);
    }),
    dispatch(type: string) {
      for (const listener of listeners.get(type) ?? []) listener.call(this, new Event(type));
    },
  };
};

const element = () => Object.assign(eventTarget(), {
  checked: false,
  value: "",
  classList: { add: vi.fn() },
  appendChild: vi.fn(),
});

let maximizeCheck: ReturnType<typeof element>;
let fullscreenCheck: ReturnType<typeof element>;
let effectsCheck: ReturnType<typeof element>;
let colorsSelect: ReturnType<typeof element>;
let documentTarget: ReturnType<typeof eventTarget>;
let windowTarget: ReturnType<typeof eventTarget>;
let mediaQuery: ReturnType<typeof eventTarget> & { matches: boolean };
let app: any;

const boot = async ({ touch = false, fullscreen = false } = {}) => {
  mocks.isTouch = touch;
  mocks.isFullscreen = fullscreen;

  maximizeCheck = element();
  fullscreenCheck = element();
  effectsCheck = element();
  colorsSelect = element();
  documentTarget = eventTarget();
  windowTarget = eventTarget();
  mediaQuery = Object.assign(eventTarget(), { matches: touch });

  app = {
    setup: vi.fn(),
    apply_color_scheme: vi.fn(),
    viewport: { layout: vi.fn(), schedule_layout: vi.fn() },
    menu: { open: vi.fn(), for_each: vi.fn() },
    game: { for_each: vi.fn(), draw: vi.fn() },
    settings: {
      color: "default",
      colors: { default: {}, high_contrast: {} },
      graphics: { effects: true, draw_borders: false },
    },
  };
  mocks.application = app;

  const elements: Record<string, ReturnType<typeof element>> = {
    "#maximizeCheck": maximizeCheck,
    "#fullScreenCheck": fullscreenCheck,
    "#effectsCheck": effectsCheck,
    "#highscorelink": element(),
    "select#colors": colorsSelect,
  };

  vi.stubGlobal("window", windowTarget);
  vi.stubGlobal("document", Object.assign(documentTarget, {
    documentElement: { classList: { add: vi.fn() } },
    querySelector: vi.fn((selector: string) => elements[selector]),
    querySelectorAll: vi.fn(() => []),
    createElement: vi.fn(() => ({ value: "", textContent: "", selected: false })),
  }));
  vi.stubGlobal("navigator", { maxTouchPoints: touch ? 1 : 0 });
  vi.stubGlobal("matchMedia", vi.fn(() => mediaQuery));
  vi.stubGlobal("confirm", vi.fn());
  vi.stubGlobal("console", { ...console, time: vi.fn() });

  await import("../src/main.coffee");
  (windowTarget as any).onload();
};

beforeEach(() => {
  vi.resetModules();
  mocks.Naubino.mockClear();
  mocks.toggleFullscreen.mockReset();
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("browser layout wiring", () => {
  it("lays out initially and derives maximize policy from the checkbox or fullscreen state", async () => {
    await boot();

    expect(app.setup).toHaveBeenCalledOnce();
    expect(app.apply_color_scheme).toHaveBeenCalledOnce();
    expect(effectsCheck.checked).toBe(true);
    expect(app.viewport.layout).toHaveBeenCalledWith({ maximized: false, fit: true });

    maximizeCheck.checked = true;
    maximizeCheck.dispatch("change");
    expect(app.viewport.layout).toHaveBeenLastCalledWith({ maximized: true, fit: true });

    maximizeCheck.checked = false;
    mocks.isFullscreen = true;
    maximizeCheck.dispatch("change");
    expect(app.viewport.layout).toHaveBeenLastCalledWith({ maximized: true, fit: true });

    fullscreenCheck.dispatch("change");
    expect(mocks.toggleFullscreen).toHaveBeenCalledOnce();
  });

  it("schedules resize using touch fit policy and the orientation delay", async () => {
    await boot({ touch: true });
    app.viewport.schedule_layout.mockClear();

    windowTarget.dispatch("resize");
    expect(app.viewport.schedule_layout).toHaveBeenCalledWith({ maximized: true, fit: true });

    windowTarget.dispatch("orientationchange");
    expect(app.viewport.schedule_layout).toHaveBeenLastCalledWith({ maximized: true, fit: true }, 300);
  });

  it("enables maximized touch startup and opens the menu", async () => {
    await boot({ touch: true });

    expect((document.documentElement as any).classList.add).toHaveBeenCalledWith("touch");
    expect(maximizeCheck.checked).toBe(true);
    expect(app.menu.open).toHaveBeenCalledOnce();
    expect(app.viewport.layout).toHaveBeenCalledWith({ maximized: true, fit: true });
  });

  it("syncs fullscreen UI and performs immediate plus scheduled layout", async () => {
    await boot();
    app.viewport.layout.mockClear();
    app.viewport.schedule_layout.mockClear();
    mocks.isFullscreen = true;

    documentTarget.dispatch("fullscreenchange");

    expect(fullscreenCheck.checked).toBe(true);
    expect(app.viewport.layout).toHaveBeenCalledWith({ maximized: true, fit: true });
    expect(app.viewport.schedule_layout).toHaveBeenCalledWith({ maximized: true, fit: false });
  });
});
