import { afterEach, describe, expect, it, vi } from "vitest";
import { Layer } from "../src/core/Layer";
import { Overlay } from "../src/ui/Overlay";
import { Menu } from "../src/ui/Menu";

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

describe("runtime render dimensions", () => {
  it("scales each layer's live dimensions rather than configured canvas defaults", () => {
    vi.stubGlobal("window", { devicePixelRatio: 2 });
    const layer = Object.assign(Object.create(Layer.prototype), {
      width: 640,
      height: 360,
      canvas: { width: 800, height: 450, style: {} },
      ctx: { setTransform: vi.fn(), clearRect: vi.fn() },
    });

    layer.scale_to(1.5);

    expect(layer.canvas.style).toEqual({ width: "960px", height: "540px" });
    expect(layer.canvas.width).toBe(1920);
    expect(layer.canvas.height).toBe(1080);
    expect(layer.ctx.setTransform).toHaveBeenCalledWith(3, 0, 0, 3, 0, 0);
  });

  it("clears menu and overlay canvases without accessing a global game canvas", () => {
    vi.stubGlobal("Naubino", undefined);
    const ctx = { clearRect: vi.fn(), save: vi.fn(), restore: vi.fn() };
    const overlay = Object.assign(Object.create(Overlay.prototype), {
      canvas: { width: 640, height: 360 },
      ctx,
      objects: {},
      can: () => false,
    });
    overlay.draw();
    expect(ctx.clearRect).toHaveBeenLastCalledWith(0, 0, 640, 360);

    const main = { draw: vi.fn(), draw_joins: vi.fn(), draw_join: vi.fn() };
    const menu = Object.assign(Object.create(Menu.prototype), {
      canvas: { width: 320, height: 180 },
      ctx,
      objects: { main },
    });
    menu.draw_menu();
    expect(ctx.clearRect).toHaveBeenLastCalledWith(0, 0, 320, 180);
  });

  it("sizes newly created text buffers from the overlay's current dimensions", () => {
    const buffer = { width: 0, height: 0, getContext: () => ({}) };
    vi.stubGlobal("document", { createElement: vi.fn(() => buffer) });
    const overlay = Object.assign(Object.create(Overlay.prototype), {
      width: 640,
      height: 360,
      can: () => false,
      add_object: vi.fn((textBuffer) => textBuffer),
    });
    const ctx = {
      clearRect: vi.fn(),
      fillText: vi.fn(),
      strokeText: vi.fn(),
    };
    buffer.getContext = () => ctx;
    const text = { text: "test", life: true, color: "white", fontsize: 20, font: "sans-serif", x: 10, y: 20 };

    overlay.message(text);

    expect(buffer.width).toBe(640);
    expect(buffer.height).toBe(360);
    expect(overlay.add_object).toHaveBeenCalledOnce();
  });
});
