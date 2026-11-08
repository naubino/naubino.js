import { describe, expect, it, vi } from "vitest";
import { Input } from "../src/Input";

type Listener = (event: any) => void;

class EventTargetFake {
  listeners = new Map<string, Listener[]>();
  additions: Array<[string, Listener, AddEventListenerOptions | boolean | undefined]> = [];

  addEventListener(type: string, listener: Listener, options?: AddEventListenerOptions | boolean) {
    this.additions.push([type, listener, options]);
    this.listeners.set(type, [...(this.listeners.get(type) ?? []), listener]);
  }

  removeEventListener(type: string, listener: Listener) {
    this.listeners.set(type, (this.listeners.get(type) ?? []).filter((item) => item !== listener));
  }

  emit(type: string, event: Record<string, unknown> = {}) {
    for (const listener of this.listeners.get(type) ?? []) listener({ type, ...event });
  }
}

const touch = (clientX: number, clientY: number) => ({ clientX, clientY });

const setup = () => {
  const canvas = new EventTargetFake();
  const keyboard = new EventTargetFake();
  const viewport = { to_local: vi.fn((x: number, y: number) => ({ x: x - 10, y: y - 20 })) };
  const signals = {
    mousedown: { dispatch: vi.fn() },
    mousemove: { dispatch: vi.fn() },
    mouseup: { dispatch: vi.fn() },
  };
  const toggle = vi.fn();
  const stop = vi.fn();
  const input = new Input({ canvas, viewport, signals, toggle, stop, keyboard_target: keyboard });
  return { canvas, input, keyboard, signals, stop, toggle, viewport };
};

describe("Input", () => {
  it("binds once and uses passive-false touch listeners", () => {
    const { canvas, input, keyboard } = setup();

    input.bind();
    input.bind();

    expect(keyboard.additions.map(([type]) => type)).toEqual(["keydown", "keyup"]);
    expect(canvas.additions.map(([type]) => type)).toEqual([
      "mousedown", "mousemove", "mouseup", "mouseout", "touchstart", "touchmove", "touchend", "touchcancel",
    ]);
    expect(canvas.additions.filter(([type]) => type.startsWith("touch")).every(([, , options]) =>
      (options as AddEventListenerOptions).passive === false,
    )).toBe(true);
  });

  it("dispatches mouse events in viewport-local coordinates and releases on mouseout", () => {
    const { canvas, input, signals, viewport } = setup();
    input.bind();

    canvas.emit("mousedown", { clientX: 30, clientY: 50 });
    canvas.emit("mousemove", { clientX: 31, clientY: 51 });
    canvas.emit("mouseout", { clientX: 32, clientY: 52 });

    expect(viewport.to_local).toHaveBeenNthCalledWith(1, 30, 50, canvas);
    expect(signals.mousedown.dispatch).toHaveBeenCalledWith(20, 30);
    expect(signals.mousemove.dispatch).toHaveBeenCalledWith(21, 31);
    expect(signals.mouseup.dispatch).toHaveBeenCalledWith(22, 32);
  });

  it("uses changed touch coordinates and prevents synthetic mouse events", () => {
    const { canvas, input, signals, viewport } = setup();
    const preventDefault = vi.fn();
    input.bind();

    canvas.emit("touchstart", {
      changedTouches: [touch(40, 60)],
      touches: [touch(40, 60)],
      preventDefault,
    });
    canvas.emit("touchmove", {
      changedTouches: [touch(41, 61)],
      touches: [touch(41, 61)],
      preventDefault,
    });

    expect(viewport.to_local).toHaveBeenNthCalledWith(1, 40, 60, canvas);
    expect(signals.mousedown.dispatch).toHaveBeenCalledWith(30, 40);
    expect(signals.mousemove.dispatch).toHaveBeenCalledWith(31, 41);
    expect(preventDefault).toHaveBeenCalledTimes(2);
  });

  it("toggles only after a short two-finger tap fully releases", () => {
    vi.useFakeTimers();
    vi.setSystemTime(1_000);
    const { canvas, input, signals, toggle } = setup();
    input.bind();

    canvas.emit("touchstart", { changedTouches: [touch(1, 2)], touches: [touch(1, 2)], preventDefault: vi.fn() });
    canvas.emit("touchstart", { changedTouches: [touch(3, 4)], touches: [touch(1, 2), touch(3, 4)], preventDefault: vi.fn() });
    expect(signals.mouseup.dispatch).toHaveBeenCalledWith(-7, -16);

    vi.advanceTimersByTime(399);
    canvas.emit("touchend", { touches: [touch(1, 2)], preventDefault: vi.fn() });
    expect(toggle).not.toHaveBeenCalled();
    canvas.emit("touchend", { touches: [], preventDefault: vi.fn() });
    expect(toggle).toHaveBeenCalledTimes(1);
    vi.useRealTimers();
  });

  it("releases cancelled touches and does not toggle cancelled or long two-finger gestures", () => {
    vi.useFakeTimers();
    const { canvas, input, signals, toggle } = setup();
    input.bind();

    canvas.emit("touchstart", { changedTouches: [touch(1, 2)], touches: [touch(1, 2)], preventDefault: vi.fn() });
    canvas.emit("touchcancel", { changedTouches: [touch(1, 2)], touches: [], preventDefault: vi.fn() });
    expect(signals.mouseup.dispatch).toHaveBeenCalledWith(-9, -18);

    canvas.emit("touchstart", { changedTouches: [touch(1, 2)], touches: [touch(1, 2), touch(3, 4)], preventDefault: vi.fn() });
    canvas.emit("touchcancel", { touches: [], preventDefault: vi.fn() });
    canvas.emit("touchstart", { changedTouches: [touch(1, 2)], touches: [touch(1, 2), touch(3, 4)], preventDefault: vi.fn() });
    vi.advanceTimersByTime(400);
    canvas.emit("touchend", { touches: [], preventDefault: vi.fn() });

    expect(toggle).not.toHaveBeenCalled();
    vi.useRealTimers();
  });

  it("suppresses repeated keydown actions and unbind resets state", () => {
    const { canvas, input, keyboard, signals, stop, toggle } = setup();
    input.bind();

    keyboard.emit("keydown", { which: 32 });
    keyboard.emit("keydown", { which: 32 });
    keyboard.emit("keyup", { which: 32 });
    keyboard.emit("keydown", { which: 27 });
    expect(toggle).toHaveBeenCalledTimes(1);
    expect(stop).toHaveBeenCalledTimes(1);

    input.unbind();
    keyboard.emit("keydown", { which: 32 });
    canvas.emit("mousedown", { clientX: 30, clientY: 50 });
    expect(toggle).toHaveBeenCalledTimes(1);
    expect(signals.mousedown.dispatch).not.toHaveBeenCalled();

    input.bind();
    keyboard.emit("keydown", { which: 32 });
    expect(toggle).toHaveBeenCalledTimes(2);
  });
});
