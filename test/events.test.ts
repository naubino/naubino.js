import { describe, expect, it, vi } from "vitest";
import { Events } from "../src/Events";

describe("Events", () => {
  it("provides the application event contract", () => {
    const events = new Events();

    expect(Object.keys(events.input)).toEqual([
      "pointer_start", "pointer_move", "pointer_end",
      "two_finger_start", "two_finger_end", "two_finger_tap",
    ]);
    expect(Object.keys(events.commands)).toEqual(["play", "pause", "stop", "toggle"]);
    expect(Object.keys(events.game)).toEqual(["outcome", "overflow_warning", "basket_changed"]);
    expect(Object.keys(events.session)).toEqual(["state_changed"]);
    expect(Object.keys(events.menu)).toEqual(["button", "focus", "blur"]);
  });

  it("keeps separate applications isolated", () => {
    const first = new Events();
    const second = new Events();
    const listener = vi.fn();
    first.commands.play.add(listener);

    second.commands.play.dispatch();
    first.commands.play.dispatch("manual");

    expect(listener).toHaveBeenCalledOnce();
    expect(listener).toHaveBeenCalledWith("manual");
  });
});
