import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Viewport } from "../src/Viewport";

type FakeCanvas = {
  width: number;
  height: number;
  id?: string;
  style: Record<string, string>;
  clientWidth: number;
  clientLeft: number;
  clientTop: number;
  offsetWidth: number;
  offsetTop: number;
  setAttribute: (name: string, value: string) => void;
  getBoundingClientRect: () => { left: number; top: number };
};

const canvas = (): FakeCanvas => ({
  width: 0,
  height: 0,
  style: {},
  clientWidth: 0,
  clientLeft: 0,
  clientTop: 0,
  offsetWidth: 0,
  offsetTop: 0,
  setAttribute(name, value) {
    if (name === "id") this.id = value;
  },
  getBoundingClientRect() {
    return { left: 0, top: 0 };
  },
});

describe("Viewport", () => {
  let container: { children: FakeCanvas[]; appendChild: (child: FakeCanvas) => void };

  beforeEach(() => {
    container = {
      children: [],
      appendChild(child) {
        this.children.push(child);
      },
    };
    vi.stubGlobal("window", { innerWidth: 1000, innerHeight: 800 });
    vi.stubGlobal("document", { createElement: vi.fn(canvas) });
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("creates the named canvas map with the configured dimensions", () => {
    const viewport = new Viewport(container, { width: 800, height: 450, scale: 1 });

    expect(Object.keys(viewport.canvases)).toEqual([
      "background_canvas",
      "game_canvas",
      "menu_canvas",
      "overlay_canvas",
    ]);
    expect(container.children.map((child) => child.id)).toEqual([
      "background_canvas",
      "game_canvas",
      "menu_canvas",
      "overlay_canvas",
    ]);
    expect(container.children.every((child) => child.width === 800 && child.height === 450)).toBe(true);
    expect(viewport.base_size).toEqual({ width: 800, height: 450 });
    expect(Object.isFrozen(viewport.base_size)).toBe(true);
    expect((viewport as any).settings).toBeUndefined();
    expect((viewport as any).game_canvas).toBeUndefined();
  });

  it("keeps supplied canvas settings immutable while live dimensions change", () => {
    const settings = { width: 800, height: 450, scale: 2 };
    const viewport = new Viewport(container, settings);
    const layer = { canvas: canvas(), scale_to: vi.fn(), draw: vi.fn() };
    viewport.set_layers([layer]);

    viewport.resize_field(640, 360);
    viewport.scale_to(1.5);

    expect(settings).toEqual({ width: 800, height: 450, scale: 2 });
    expect(viewport).toMatchObject({ width: 640, height: 360, scale: 1.5 });
    expect(layer).toMatchObject({ width: 640, height: 360 });
  });

  it("positions FPS labels according to layer order, including after reordering", () => {
    const viewport = new Viewport(container, { width: 800, height: 450 });
    const layers = Array.from({ length: 4 }, () => ({ fps_label_depth: -1 }));

    viewport.set_layers(layers);
    expect(layers.map((layer) => layer.fps_label_depth)).toEqual([3, 2, 1, 0]);

    const reordered = [...layers].reverse();
    viewport.set_layers(reordered);
    expect(reordered.map((layer) => layer.fps_label_depth)).toEqual([3, 2, 1, 0]);
    expect(layers.map((layer) => layer.fps_label_depth)).toEqual([0, 1, 2, 3]);
  });

  it("centers layers and explicitly injected elements without querying the document", () => {
    const centered = { style: {} as Record<string, string> };
    const viewport = new Viewport(container, { width: 800, height: 450 }, { centered_elements: [centered] });
    const layer = { canvas: canvas() };
    viewport.canvases.game_canvas.clientWidth = 400;
    viewport.set_layers([layer]);

    viewport.center();

    expect(centered.style.left).toBe("300px");
    expect(layer.canvas.style.left).toBe("300px");
    expect((document as any).querySelector).toBeUndefined();
  });

  it("scales and redraws selected layers, then resizes through its callback", () => {
    const viewport = new Viewport(container, { width: 800, height: 450 });
    const background = { canvas: canvas(), scale_to: vi.fn(), draw: vi.fn() };
    const game = { canvas: canvas(), scale_to: vi.fn(), draw: vi.fn() };
    viewport.set_layers([background, game], [background]);

    viewport.scale_to(1.5);
    expect(background.scale_to).toHaveBeenCalledWith(1.5);
    expect(game.scale_to).toHaveBeenCalledWith(1.5);
    expect(background.draw).toHaveBeenCalledTimes(1);
    expect(game.draw).not.toHaveBeenCalled();

    const onResize = vi.fn();
    viewport.on_resize = onResize;
    viewport.resize_field(640, 360);
    expect(onResize).toHaveBeenCalledWith(640, 360);
  });

  it("fits from each viewport's configured base size after prior resizes", () => {
    const first = new Viewport(container, { width: 800, height: 450 });
    first.canvases.game_canvas.clientWidth = 400;
    first.canvases.game_canvas.offsetWidth = 410;
    first.canvases.game_canvas.offsetTop = 30;
    first.resize_field(640, 360);
    first.fit_field_to_viewport();

    expect(first).toMatchObject({ width: 586, height: 450 });

    const second = new Viewport(container, { width: 300, height: 500 });
    second.canvases.game_canvas.clientWidth = 400;
    second.canvases.game_canvas.offsetWidth = 410;
    second.canvases.game_canvas.offsetTop = 30;
    second.fit_field_to_viewport();

    expect(second).toMatchObject({ width: 391, height: 300 });
  });

  it("converts client coordinates to local coordinates using canvas borders and scale", () => {
    const viewport = new Viewport(container, { width: 800, height: 450 });
    const overlay = viewport.canvases.overlay_canvas;
    overlay.clientLeft = 3;
    overlay.clientTop = 5;
    overlay.getBoundingClientRect = () => ({ left: 100, top: 200 });
    viewport.scale_to(2);

    expect(viewport.to_local(143, 255)).toEqual({ x: 20, y: 25 });
  });

  it("debounces layout and uses the latest options", () => {
    vi.useFakeTimers();
    const viewport = new Viewport(container, { width: 800, height: 450 });
    const layout = vi.spyOn(viewport, "layout");

    viewport.schedule_layout({ maximized: true }, 150);
    viewport.schedule_layout({ maximized: false, fit: true }, 50);
    vi.advanceTimersByTime(50);

    expect(layout).toHaveBeenCalledTimes(1);
    expect(layout).toHaveBeenCalledWith({ maximized: false, fit: true });
  });

  it("cancels stale scheduled options when layout is applied immediately", () => {
    vi.useFakeTimers();
    const viewport = new Viewport(container, { width: 800, height: 450 });
    const maximize = vi.spyOn(viewport, "maximize");
    const demaximize = vi.spyOn(viewport, "demaximize");

    viewport.schedule_layout({ maximized: true });
    viewport.layout({ maximized: false });
    vi.advanceTimersByTime(200);

    expect(demaximize).toHaveBeenCalledOnce();
    expect(maximize).not.toHaveBeenCalled();
  });

  it("maximizes from live dimensions and can stretch all canvases", () => {
    const viewport = new Viewport(container, { width: 800, height: 450 });
    viewport.canvases.game_canvas.clientWidth = 400;
    viewport.canvases.game_canvas.offsetWidth = 410;
    viewport.canvases.game_canvas.offsetTop = 30;
    viewport.resize_field(469, 360);

    expect(viewport.available_size()).toEqual({ width: 990, height: 760 });
    viewport.maximize();
    expect(viewport.scale).toBeCloseTo(990 / 469);

    viewport.stretch();
    expect(viewport.canvases.game_canvas.style.width).toBe("100%");
    viewport.stretch("640px");
    expect(viewport.canvases.overlay_canvas.style.width).toBe("640px");
  });
});
