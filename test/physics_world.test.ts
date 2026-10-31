import { describe, expect, it } from "vitest";
import { PhysicsWorld } from "../src/world/PhysicsWorld";

interface ObjLike {
  physical_body?: unknown;
  physical_shape?: unknown;
  constraints: unknown[];
}

const makeNaubObj = (pos: unknown): ObjLike => {
  const body = new cp.Body(1, 1);
  body.setPos(pos);
  const shape = new cp.CircleShape(body, 10, cp.vzero);
  return { physical_body: body, physical_shape: shape, constraints: [] };
};

describe("PhysicsWorld", () => {
  describe("constructor", () => {
    it("creates a space with a mouse body already added", () => {
      const physics = new PhysicsWorld(100, 100);
      expect(physics.space.containsBody(physics.mouseBody)).toBe(true);
    });
  });

  describe("add_walls", () => {
    it("adds the four named walls to the space", () => {
      const physics = new PhysicsWorld(100, 100);
      physics.add_walls();
      expect(Object.keys(physics.walls).sort()).toEqual([
        "ceil",
        "floor",
        "left",
        "right",
      ]);
    });

    it("puts walls on the not-grabable mask", () => {
      const physics = new PhysicsWorld(100, 100);
      physics.add_walls();
      expect(physics.walls.ceil.layers).toBe(physics.NOT_GRABABLE_MASK);
    });
  });

  describe("add_object / remove_object", () => {
    it("adds the body and shape of an object to the space", () => {
      const physics = new PhysicsWorld(100, 100);
      const obj = makeNaubObj(new cp.Vect(10, 10));
      physics.add_object(obj);
      expect(physics.space.containsBody(obj.physical_body)).toBe(true);
      expect(physics.space.containsShape(obj.physical_shape)).toBe(true);
    });

    it("removes the body and shape of an object from the space", () => {
      const physics = new PhysicsWorld(100, 100);
      const obj = makeNaubObj(new cp.Vect(10, 10));
      physics.add_object(obj);
      physics.remove_object(obj);
      expect(physics.space.containsBody(obj.physical_body)).toBe(false);
      expect(physics.space.containsShape(obj.physical_shape)).toBe(false);
    });
  });

  describe("step", () => {
    it("drags the mouse body toward the pointer", () => {
      const physics = new PhysicsWorld(100, 100);
      const pointer = new cp.Vect(50, 50);
      physics.step(1 / 60, pointer);
      expect(physics.mouseBody.p.x).toBeGreaterThan(0);
      expect(physics.mouseBody.p.y).toBeGreaterThan(0);
    });
  });
});
