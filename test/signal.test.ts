import { describe, expect, it, vi } from "vitest";
import { Signal } from "../src/core/Signal";

describe("Signal", () => {
  it("returns an unsubscribe function from add", () => {
    const signal = new Signal();
    const listener = vi.fn();
    const unsubscribe = signal.add(listener);

    signal.dispatch("first");
    unsubscribe();
    signal.dispatch("second");

    expect(listener).toHaveBeenCalledOnce();
    expect(listener).toHaveBeenCalledWith("first");
  });
});
