import { describe, expect, it } from "vitest";
import { World } from "../src/game/World";
import { PhysicsWorld } from "../src/game/PhysicsWorld";

interface ObjLike {
  number?: number;
  isClickable: boolean;
  physical_body: any;
  physical_shape: any;
  constraints: unknown[];
}

const makeObj = (pos: unknown, isClickable = true): ObjLike => {
  const body = new cp.Body(1, 1);
  body.setPos(pos);
  const shape = new cp.CircleShape(body, 10, cp.vzero);
  return { isClickable, physical_body: body, physical_shape: shape, constraints: [] };
};

// add_object doesn't tag shapes, Game does that afterwards
const addTagged = (world: World, obj: ObjLike): number => {
  const number = world.add_object(obj);
  obj.physical_shape.naub_number = number;
  return number;
};

describe("World", () => {
  describe("constructor", () => {
    it("starts with an empty registry, a PhysicsWorld and lifecycle signals", () => {
      const world = new World(400, 300);
      expect(world.objects).toEqual({});
      expect(world.objects_count).toBe(0);
      expect(world.physics).toBeInstanceOf(PhysicsWorld);
      expect(world.naub_destroyed).toBeInstanceOf(Naubino.Signal);
      expect(world.naub_focused).toBeInstanceOf(Naubino.Signal);
      expect(world.naub_unfocused).toBeInstanceOf(Naubino.Signal);
    });
  });

  describe("add_object", () => {
    it("numbers objects sequentially starting at 1", () => {
      const world = new World(400, 300);
      const first = makeObj(new cp.Vect(10, 10));
      const second = makeObj(new cp.Vect(20, 20));
      expect(world.add_object(first)).toBe(1);
      expect(world.add_object(second)).toBe(2);
      expect(first.number).toBe(1);
      expect(world.get_object(2)).toBe(second);
    });

    it("adds the body and shape to the space", () => {
      const world = new World(400, 300);
      const obj = makeObj(new cp.Vect(10, 10));
      world.add_object(obj);
      expect(world.physics.space.containsBody(obj.physical_body)).toBe(true);
      expect(world.physics.space.containsShape(obj.physical_shape)).toBe(true);
    });
  });

  describe("remove_object", () => {
    it("drops the object from the registry and the space", () => {
      const world = new World(400, 300);
      const obj = makeObj(new cp.Vect(10, 10));
      const number = world.add_object(obj);
      world.remove_object(number);
      expect(world.get_object(number)).toBeUndefined();
      expect(world.physics.space.containsBody(obj.physical_body)).toBe(false);
      expect(world.physics.space.containsShape(obj.physical_shape)).toBe(false);
    });
  });

  describe("clear", () => {
    it("empties the registry and starts a fresh space", () => {
      const world = new World(400, 300);
      world.add_object(makeObj(new cp.Vect(10, 10)));
      const oldPhysics = world.physics;
      world.clear(400, 300);
      expect(world.objects).toEqual({});
      expect(world.physics).not.toBe(oldPhysics);
    });

    // timers from the last game (destroy_naubs, Naub.destroy) may still look ids up
    it("keeps counting object numbers after a clear", () => {
      const world = new World(400, 300);
      world.add_object(makeObj(new cp.Vect(10, 10)));
      world.clear(400, 300);
      expect(world.add_object(makeObj(new cp.Vect(10, 10)))).toBe(2);
    });
  });

  describe("reset_signals", () => {
    it("replaces the lifecycle signals, dropping old listeners", () => {
      const world = new World(400, 300);
      const oldFocused = world.naub_focused;
      world.reset_signals();
      expect(world.naub_focused).not.toBe(oldFocused);
    });
  });

  describe("naub_at", () => {
    it("returns the clickable object at the given position", () => {
      const world = new World(400, 300);
      const obj = makeObj(new cp.Vect(50, 50));
      addTagged(world, obj);
      expect(world.naub_at(new cp.Vect(50, 50))).toBe(obj);
    });

    it("returns undefined when nothing is at that position", () => {
      const world = new World(400, 300);
      addTagged(world, makeObj(new cp.Vect(50, 50)));
      expect(world.naub_at(new cp.Vect(300, 200))).toBeUndefined();
    });

    it("returns undefined when the object there is not clickable", () => {
      const world = new World(400, 300);
      addTagged(world, makeObj(new cp.Vect(50, 50), false));
      expect(world.naub_at(new cp.Vect(50, 50))).toBeUndefined();
    });
  });
});
