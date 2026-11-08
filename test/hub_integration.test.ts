import { afterEach, describe, expect, it, vi } from "vitest";
import { Events } from "../src/Events";
import { Input } from "../src/Input";
import { Session } from "../src/Session";
import { DebugMode } from "../src/modes/DebugMode";

const transitions = {
  default: [
    { name: "init", from: ["none", "stopped"], to: "stopped" },
    { name: "play", from: ["paused", "stopped"], to: "playing" },
    { name: "pause", from: ["paused", "playing"], to: "paused" },
    { name: "stop", from: "*", to: "stopped" },
  ],
  game: [{ name: "loose", from: "playing", to: "lost" }, { name: "stop", from: "lost", to: "stopped" }],
};

const target = () => {
  const listeners: Record<string, ((event: any) => void)[]> = {};
  return {
    addEventListener: vi.fn((name, listener) => { (listeners[name] ??= []).push(listener); }),
    removeEventListener: vi.fn((name, listener) => {
      listeners[name] = (listeners[name] ?? []).filter((registered) => registered !== listener);
    }),
    emit(name: string, event: any) { for (const listener of listeners[name] ?? []) listener(event); },
  };
};

const makeLayer = () => {
  const layer: any = { init: undefined, play: undefined, pause: undefined, stop: undefined };
  StateMachine.create({ target: layer, initial: "none", events: transitions.default.concat(transitions.game) });
  return layer;
};

afterEach(() => {
  vi.useRealTimers();
  vi.restoreAllMocks();
});

describe("Input, DebugMode, and Session event hub", () => {
  it("cancels a debug hold on pause and removes all subscriptions on disposal", () => {
    vi.spyOn(console, "info").mockImplementation(() => {});
    vi.useFakeTimers();
    const events = new Events();
    const canvas = target();
    const keyboard = target();
    const input = new Input({
      canvas,
      viewport: { to_local: () => ({ x: 20, y: 30 }) },
      events,
      keyboard_target: keyboard,
    });
    const game = Object.assign(makeLayer(), {
      score_snapshot: vi.fn(() => null),
      one_after_another: vi.fn(),
      fade_out: vi.fn(),
      confirm_stop: vi.fn(() => true),
    });
    const overlay = Object.assign(makeLayer(), { warning: vi.fn() });
    const background = makeLayer();
    const menu = { init: vi.fn(), play: vi.fn(), check_game_state: vi.fn() };
    const session = new Session({ game, overlay, background, menu, transitions, events });
    const mode = new DebugMode();
    mode.spawn_pair = vi.fn();
    const unbindMode = mode.bind(game, events);

    input.bind();
    input.bind();
    session.init();
    session.play();
    canvas.emit("touchstart", { changedTouches: [{ clientX: 1, clientY: 2 }], touches: [{ clientX: 1, clientY: 2 }], preventDefault: vi.fn() });
    canvas.emit("touchstart", { changedTouches: [{ clientX: 3, clientY: 4 }], touches: [{}, {}], preventDefault: vi.fn() });
    expect(mode.spawn_pair).toHaveBeenCalledOnce();

    session.pause();
    vi.advanceTimersByTime(600);
    expect(mode.spawn_pair).toHaveBeenCalledOnce();

    input.unbind();
    unbindMode();
    session.dispose();
    events.input.two_finger_start.dispatch();
    expect(mode.spawn_pair).toHaveBeenCalledOnce();
  });
});
