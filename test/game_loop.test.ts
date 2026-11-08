import { afterEach, describe, expect, it, vi } from "vitest";
import { GameLoop } from "../src/GameLoop";

describe("GameLoop", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("schedules one loop, advances layers with frame elapsed time, and cancels it", () => {
    const advance = vi.fn();
    const callbacks: FrameRequestCallback[] = [];
    const requestAnimationFrame = vi.fn((callback: FrameRequestCallback) => {
      callbacks.push(callback);
      return callbacks.length;
    });
    const cancelAnimationFrame = vi.fn();

    vi.stubGlobal("performance", { now: vi.fn(() => 100) });
    vi.stubGlobal("requestAnimationFrame", requestAnimationFrame);
    vi.stubGlobal("cancelAnimationFrame", cancelAnimationFrame);

    const loop = new GameLoop([{ advance }]);
    loop.start();
    loop.start();

    expect(requestAnimationFrame).toHaveBeenCalledTimes(1);

    callbacks[0](116);
    expect(advance).toHaveBeenCalledWith(16);
    expect(requestAnimationFrame).toHaveBeenCalledTimes(2);

    loop.stop();
    expect(cancelAnimationFrame).toHaveBeenCalledWith(2);

    callbacks[1](132);
    expect(advance).toHaveBeenCalledTimes(1);
  });
});
