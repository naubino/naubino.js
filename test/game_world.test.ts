import { describe, expect, it, vi } from "vitest";
import { Game } from "../src/Game";
import { World } from "../src/world/World";

// skips the constructor, no canvas or fsm needed for the world plumbing
const makeGame = () =>
  Object.assign(Object.create(Game.prototype), {
    width: 400,
    height: 300,
    world: new World(400, 300),
    graph: { clear: vi.fn() },
    center: () => new cp.Vect(200, 150),
  });

const makeNaub = () => {
  const body = new cp.Body(1, 1);
  const shape = new cp.CircleShape(body, 10, cp.vzero);
  return {
    physical_body: body,
    physical_shape: shape,
    constraints: [],
    attracted_to: vi.fn(),
  };
};

const expectExposed = (game: any) => {
  expect(game.objects).toBe(game.world.objects);
  expect(game.physics).toBe(game.world.physics);
  expect(game.space).toBe(game.world.physics.space);
  expect(game.mouseBody).toBe(game.world.physics.mouseBody);
  expect(game.GRABABLE_MASK_BIT).toBe(game.world.physics.GRABABLE_MASK_BIT);
  expect(game.naub_destroyed).toBe(game.world.naub_destroyed);
  expect(game.naub_focused).toBe(game.world.naub_focused);
  expect(game.naub_unfocused).toBe(game.world.naub_unfocused);
};

describe("Game world plumbing", () => {
  it("expose_world copies the world's live references onto the game", () => {
    const game = makeGame();
    game.expose_world();
    expectExposed(game);
  });

  it("setup_physics swaps in a fresh space and re-exposes it", () => {
    const game = makeGame();
    game.expose_world();
    const oldSpace = game.space;
    game.setup_physics();
    expect(game.space).not.toBe(oldSpace);
    expectExposed(game);
  });

  it("clear_objects empties the world, re-exposes it and clears the graph", () => {
    const game = makeGame();
    game.expose_world();
    game.add_object(makeNaub());
    const oldSpace = game.space;

    game.clear_objects();

    expect(game.objects).toEqual({});
    expect(game.space).not.toBe(oldSpace);
    expect(game.graph.clear).toHaveBeenCalled();
    expectExposed(game);
  });

  it("add_object registers the naub, tags body and shape, and attracts it to the center", () => {
    const game = makeGame();
    game.expose_world();
    const naub = makeNaub();

    game.add_object(naub);

    expect(game.get_object(1)).toBe(naub);
    expect(naub.physical_body.naub_number).toBe(1);
    expect(naub.physical_shape.naub_number).toBe(1);
    expect(naub.attracted_to).toHaveBeenCalled();
    expect(game.space.containsBody(naub.physical_body)).toBe(true);
  });

  it("remove_obj takes the naub out of the world", () => {
    const game = makeGame();
    game.expose_world();
    const naub = makeNaub();
    game.add_object(naub);

    game.remove_obj(1);

    expect(game.get_object(1)).toBeUndefined();
    expect(game.space.containsBody(naub.physical_body)).toBe(false);
  });
});
