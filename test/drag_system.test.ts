import { describe, expect, it, vi } from "vitest";
import { DragSystem } from "../src/DragSystem";
import { PhysicsWorld } from "../src/PhysicsWorld";

interface NaubLike {
  number: number;
  isClickable: boolean;
  physical_body: unknown;
  focus: ReturnType<typeof vi.fn>;
  unfocus: ReturnType<typeof vi.fn>;
}

interface FakeGame {
  space: PhysicsWorld["space"];
  GRABABLE_MASK_BIT: number;
  mouseBody: PhysicsWorld["mouseBody"];
  get_object(id: number): NaubLike | undefined;
  focused_naub: NaubLike | null;
  active_tree: number[];
}

const makeGame = (): {
  game: FakeGame;
  physics: PhysicsWorld;
  objects: Record<number, NaubLike>;
} => {
  const physics = new PhysicsWorld(400, 300);
  const objects: Record<number, NaubLike> = {};
  const game: FakeGame = {
    space: physics.space,
    GRABABLE_MASK_BIT: physics.GRABABLE_MASK_BIT,
    mouseBody: physics.mouseBody,
    get_object: (id) => objects[id],
    focused_naub: null,
    active_tree: [1, 2, 3],
  };
  return { game, physics, objects };
};

// real body and shape, otherwise the point query finds nothing
const addNaub = (
  objects: Record<number, NaubLike>,
  physics: PhysicsWorld,
  number: number,
  pos: unknown,
  isClickable = true,
): NaubLike => {
  const body = new cp.Body(1, 1);
  body.setPos(pos);
  const shape = new cp.CircleShape(body, 10, cp.vzero);
  shape.naub_number = number;
  physics.space.addBody(body);
  physics.space.addShape(shape);

  const naub: NaubLike = {
    number,
    isClickable,
    physical_body: body,
    focus: vi.fn(),
    unfocus: vi.fn(),
  };
  objects[number] = naub;
  return naub;
};

describe("DragSystem", () => {
  describe("start", () => {
    it("focuses the naub under the pointer and pivot-joins it to the mouse body", () => {
      const { game, physics, objects } = makeGame();
      const naub = addNaub(objects, physics, 1, new cp.Vect(50, 50));
      const drag = new DragSystem(game);

      drag.start(new cp.Vect(50, 50));

      expect(naub.focus).toHaveBeenCalled();
      expect(game.focused_naub).toBe(naub);
      expect(game.mouseBody.p.x).toBe(50);
      expect(game.mouseBody.p.y).toBe(50);

      const pivots = physics.space.constraints.filter((c: unknown) =>
        c instanceof cp.PivotJoint
      );
      expect(pivots.length).toBe(1);
    });

    it("does nothing when there is no naub under the pointer", () => {
      const { game, physics } = makeGame();
      const drag = new DragSystem(game);

      drag.start(new cp.Vect(500, 500));

      expect(game.focused_naub).toBeNull();
      expect(physics.space.constraints.length).toBe(0);
    });

    it("does nothing when the naub under the pointer is not clickable", () => {
      const { game, physics, objects } = makeGame();
      addNaub(objects, physics, 1, new cp.Vect(50, 50), false);
      const drag = new DragSystem(game);

      drag.start(new cp.Vect(50, 50));

      expect(game.focused_naub).toBeNull();
      expect(physics.space.constraints.length).toBe(0);
    });
  });

  describe("stop", () => {
    it("unfocuses the dragged naub, removes the pivot joint and resets active_tree", () => {
      const { game, physics, objects } = makeGame();
      const naub = addNaub(objects, physics, 1, new cp.Vect(50, 50));
      const drag = new DragSystem(game);
      drag.start(new cp.Vect(50, 50));

      drag.stop();

      expect(naub.unfocus).toHaveBeenCalled();
      expect(game.focused_naub).toBeNull();
      expect(physics.space.constraints.length).toBe(0);
      expect(game.active_tree).toEqual([]);
    });

    it("does nothing harmful when nothing is being dragged", () => {
      const { game } = makeGame();
      const drag = new DragSystem(game);
      expect(() => drag.stop()).not.toThrow();
      expect(game.active_tree).toEqual([]);
    });
  });
});
