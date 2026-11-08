import { describe, expect, it, vi } from "vitest";
import { Events } from "../src/Events";
import { Input } from "../src/Input";

if (typeof globalThis.CustomEvent === "undefined") {
  Object.defineProperty(globalThis, "CustomEvent", {
    configurable: true,
    value: class CustomEventPolyfill<T = unknown> extends Event {
      detail: T;

      constructor(type: string, init: CustomEventInit<T> = {}) {
        super(type, init);
        this.detail = init.detail as T;
      }
    },
  });
}

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
  const events = new Events();
  const input = new Input({ canvas, viewport, events, keyboard_target: keyboard });
  return { canvas, events, input, keyboard, viewport };
};

const twoFingerStart = (canvas: EventTargetFake, preventDefault = vi.fn()) => {
  canvas.emit("touchstart", { changedTouches: [touch(1, 2)], touches: [touch(1, 2)], preventDefault });
  canvas.emit("touchstart", {
    changedTouches: [touch(3, 4)],
    touches: [touch(1, 2), touch(3, 4)],
    preventDefault,
  });
  return preventDefault;
};

describe("Input", () => {
  it("binds once, uses passive-false touch listeners, and does not leak listeners on rebind", () => {
    const { canvas, input, keyboard } = setup();

    input.bind();
    input.bind();
    input.unbind();
    input.bind();

    expect(keyboard.additions.map(([type]) => type)).toEqual(["keydown", "keyup", "keydown", "keyup"]);
    expect(canvas.additions.map(([type]) => type)).toEqual([
      "mousedown", "mousemove", "mouseup", "mouseout", "touchstart", "touchmove", "touchend", "touchcancel",
      "mousedown", "mousemove", "mouseup", "mouseout", "touchstart", "touchmove", "touchend", "touchcancel",
    ]);
    expect(canvas.additions.filter(([type]) => type.startsWith("touch")).every(([, , options]) =>
      (options as AddEventListenerOptions).passive === false,
    )).toBe(true);
  });

  it("emits pointer phases in viewport-local coordinates and releases on mouseout", () => {
    const { canvas, events, input, viewport } = setup();
    const start = vi.fn();
    const move = vi.fn();
    const end = vi.fn();
    events.input.pointer_start.add(start);
    events.input.pointer_move.add(move);
    events.input.pointer_end.add(end);
    input.bind();

    canvas.emit("mousedown", { clientX: 30, clientY: 50 });
    canvas.emit("mousemove", { clientX: 31, clientY: 51 });
    canvas.emit("mouseout", { clientX: 32, clientY: 52 });

    expect(viewport.to_local).toHaveBeenNthCalledWith(1, 30, 50, canvas);
    expect(start).toHaveBeenCalledWith(20, 30);
    expect(move).toHaveBeenCalledWith(21, 31);
    expect(end).toHaveBeenCalledWith(22, 32);
  });

  it("uses changed touch coordinates and suppresses emulated mouse events", () => {
    const { canvas, events, input, viewport } = setup();
    const start = vi.fn();
    const move = vi.fn();
    events.input.pointer_start.add(start);
    events.input.pointer_move.add(move);
    input.bind();
    const preventDefault = vi.fn();

    canvas.emit("touchstart", { changedTouches: [touch(40, 60)], touches: [touch(40, 60)], preventDefault });
    canvas.emit("touchmove", { changedTouches: [touch(41, 61)], touches: [touch(41, 61)], preventDefault });
    canvas.emit("mousedown", { clientX: 40, clientY: 60 });

    expect(viewport.to_local).toHaveBeenNthCalledWith(1, 40, 60, canvas);
    expect(start).toHaveBeenCalledWith(30, 40);
    expect(move).toHaveBeenCalledWith(31, 41);
    expect(preventDefault).toHaveBeenCalledTimes(2);
  });

  it("dispatches keyboard commands once per held key and resets held keys on unbind", () => {
    const { canvas, events, input, keyboard } = setup();
    const toggle = vi.fn();
    const stop = vi.fn();
    const pointerStart = vi.fn();
    events.commands.toggle.add(toggle);
    events.commands.stop.add(stop);
    events.input.pointer_start.add(pointerStart);
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
    expect(pointerStart).not.toHaveBeenCalled();

    input.bind();
    keyboard.emit("keydown", { which: 32 });
    expect(toggle).toHaveBeenCalledTimes(2);
  });

  it("emits two-finger facts, not a toggle command, after staggered or simultaneous short releases", () => {
    vi.useFakeTimers();
    vi.setSystemTime(1_000);
    const { canvas, events, input } = setup();
    const start = vi.fn();
    const end = vi.fn();
    const tap = vi.fn();
    const toggle = vi.fn();
    events.input.two_finger_start.add(start);
    events.input.two_finger_end.add(end);
    events.input.two_finger_tap.add(tap);
    events.commands.toggle.add(toggle);
    input.bind();

    twoFingerStart(canvas);
    vi.advanceTimersByTime(399);
    canvas.emit("touchend", { touches: [touch(1, 2)], preventDefault: vi.fn() });
    canvas.emit("touchend", { touches: [], preventDefault: vi.fn() });

    twoFingerStart(canvas);
    canvas.emit("touchend", { touches: [], preventDefault: vi.fn() });

    expect(start).toHaveBeenCalledTimes(2);
    expect(end).toHaveBeenCalledTimes(2);
    expect(tap).toHaveBeenCalledTimes(2);
    expect(toggle).not.toHaveBeenCalled();
    vi.useRealTimers();
  });

  it("cancels gestures on non-playing session states and safely handles synchronous state changes during tap publication", () => {
    const { canvas, events, input } = setup();
    const end = vi.fn();
    const tap = vi.fn(() => events.session.state_changed.dispatch("paused"));
    events.input.two_finger_end.add(end);
    events.input.two_finger_tap.add(tap);
    input.bind();

    twoFingerStart(canvas);
    events.session.state_changed.dispatch("playing");
    expect(end).not.toHaveBeenCalled();
    events.session.state_changed.dispatch("paused");
    expect(end).toHaveBeenCalledTimes(1);

    twoFingerStart(canvas);
    canvas.emit("touchend", { touches: [], preventDefault: vi.fn() });
    expect(tap).toHaveBeenCalledTimes(1);
    expect(end).toHaveBeenCalledTimes(2);
  });

  it("invalidates three-finger gestures without emitting stray pointer facts or taps", () => {
    const { canvas, events, input } = setup();
    const start = vi.fn();
    const end = vi.fn();
    const tap = vi.fn();
    const pointerEnd = vi.fn();
    events.input.two_finger_start.add(start);
    events.input.two_finger_end.add(end);
    events.input.two_finger_tap.add(tap);
    events.input.pointer_end.add(pointerEnd);
    input.bind();
    const preventDefault = vi.fn();

    twoFingerStart(canvas, preventDefault);
    canvas.emit("touchstart", {
      changedTouches: [touch(5, 6)],
      touches: [touch(1, 2), touch(3, 4), touch(5, 6)],
      preventDefault,
    });
    canvas.emit("touchend", { touches: [touch(1, 2), touch(3, 4)], preventDefault });
    canvas.emit("touchend", { touches: [], preventDefault });

    expect(start).toHaveBeenCalledOnce();
    expect(end).toHaveBeenCalledOnce();
    expect(tap).not.toHaveBeenCalled();
    expect(pointerEnd).toHaveBeenCalledOnce();
  });

  it("ends active gestures before unsubscribing and retains exactly one session listener after rebind", () => {
    const { canvas, events, input } = setup();
    const end = vi.fn();
    events.input.two_finger_end.add(end);
    input.bind();
    twoFingerStart(canvas);

    input.unbind();
    expect(end).toHaveBeenCalledTimes(1);
    events.session.state_changed.dispatch("paused");
    expect(end).toHaveBeenCalledTimes(1);

    input.bind();
    const cancelGesture = vi.spyOn(input, "cancel_gesture");
    events.session.state_changed.dispatch("paused");
    expect(cancelGesture).toHaveBeenCalledTimes(1);
  });
});
