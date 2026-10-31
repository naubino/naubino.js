import { describe, expect, it } from "vitest";
import { Physical_Layer } from "../src/Physical_Layer";
import { PhysicsWorld } from "../src/world/PhysicsWorld";

interface NaubLike {
  number: number;
  isClickable: boolean;
}

interface LayerLike {
  space: unknown;
  GRABABLE_MASK_BIT: number;
  get_object(id: number): NaubLike;
}

const GRABABLE_MASK_BIT = 1 << 31;

// adds a circle shape at pos, tagged with naub_number, to a fresh space
const addNaubShape = (space: any, number: number, pos: unknown) => {
  const body = new cp.Body(1, 1);
  body.setPos(pos);
  const shape = new cp.CircleShape(body, 10, cp.vzero);
  shape.naub_number = number;
  space.addBody(body);
  space.addShape(shape);
  return shape;
};

const makeLayer = (overrides: Partial<LayerLike> = {}): LayerLike =>
  Object.assign(
    {
      space: new cp.Space(),
      GRABABLE_MASK_BIT,
      get_object: (number: number): NaubLike => ({ number, isClickable: true }),
    },
    overrides,
  );

const getObjInPos = (layer: LayerLike, pos: unknown) =>
  Physical_Layer.prototype.get_obj_in_pos.call(layer, pos);

const makeCanvas = () => ({
  width: 400,
  height: 300,
  style: {},
  getContext: () => ({}),
});

describe("Physical_Layer", () => {
  describe("setup_physics", () => {
    it("builds a PhysicsWorld and keeps space/mouseBody/masks exposed directly", () => {
      const layer = new (Physical_Layer as any)(makeCanvas());
      layer.setup_physics();
      expect(layer.physics).toBeInstanceOf(PhysicsWorld);
      expect(layer.space).toBe(layer.physics.space);
      expect(layer.mouseBody).toBe(layer.physics.mouseBody);
      expect(layer.GRABABLE_MASK_BIT).toBe(layer.physics.GRABABLE_MASK_BIT);
      expect(layer.NOT_GRABABLE_MASK).toBe(layer.physics.NOT_GRABABLE_MASK);
    });
  });

  describe("add_object / remove_obj", () => {
    const makePhysicalNaub = (pos: unknown) => {
      const body = new cp.Body(1, 1);
      body.setPos(pos);
      const shape = new cp.CircleShape(body, 10, cp.vzero);
      return { physical_body: body, physical_shape: shape, constraints: [] };
    };

    it("adds a new object to the physics space", () => {
      const layer = new (Physical_Layer as any)(makeCanvas());
      layer.setup_physics();
      const naub = makePhysicalNaub(new cp.Vect(10, 10));
      layer.add_object(naub);
      expect(layer.space.containsBody(naub.physical_body)).toBe(true);
      expect(layer.space.containsShape(naub.physical_shape)).toBe(true);
    });

    it("removes an object from the physics space", () => {
      const layer = new (Physical_Layer as any)(makeCanvas());
      layer.setup_physics();
      const naub = makePhysicalNaub(new cp.Vect(10, 10));
      layer.add_object(naub);
      layer.objects[1] = naub;
      layer.remove_obj(1);
      expect(layer.space.containsBody(naub.physical_body)).toBe(false);
      expect(layer.space.containsShape(naub.physical_shape)).toBe(false);
      expect(layer.objects[1]).toBeUndefined();
    });
  });

  describe("get_obj_in_pos", () => {
    it("returns the naub at the given position", () => {
      const layer = makeLayer();
      addNaubShape(layer.space, 1, new cp.Vect(50, 50));
      expect(getObjInPos(layer, new cp.Vect(50, 50))).toEqual({
        number: 1,
        isClickable: true,
      });
    });

    it("returns undefined when nothing is at that position", () => {
      const layer = makeLayer();
      addNaubShape(layer.space, 1, new cp.Vect(50, 50));
      expect(getObjInPos(layer, new cp.Vect(500, 500))).toBeUndefined();
    });

    it("returns undefined when the hit naub is not clickable", () => {
      const layer = makeLayer({
        get_object: (number) => ({ number, isClickable: false }),
      });
      addNaubShape(layer.space, 1, new cp.Vect(50, 50));
      expect(getObjInPos(layer, new cp.Vect(50, 50))).toBeUndefined();
    });
  });
});
