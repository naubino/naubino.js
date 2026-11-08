import { afterEach, describe, expect, it, vi } from "vitest";
import { Events } from "../src/Events";
import { Menu } from "../src/ui/Menu";

const canvas = () => ({
  width: 200,
  height: 100,
  style: {},
  getContext: vi.fn(() => ({})),
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("Menu event hub integration", () => {
  it("dispatches button commands and removes pointer listeners when disposed", () => {
    const events = new Events();
    const move = vi.spyOn(Menu.prototype, "move_pointer").mockImplementation(() => {});
    const click = vi.spyOn(Menu.prototype, "click").mockImplementation(() => {});
    const play = vi.fn();
    events.commands.play.add(play);
    const menu = new Menu(canvas(), events);

    menu.command_callback("play")();
    events.input.pointer_move.dispatch(20, 30);
    events.input.pointer_start.dispatch(20, 30);

    expect(play).toHaveBeenCalledOnce();
    expect(move).toHaveBeenCalledWith(20, 30);
    expect(click).toHaveBeenCalledWith(20, 30);

    menu.dispose();
    events.input.pointer_move.dispatch(40, 50);
    events.input.pointer_start.dispatch(40, 50);

    expect(move).toHaveBeenCalledOnce();
    expect(click).toHaveBeenCalledOnce();
  });
});
