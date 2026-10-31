import { describe, expect, it, vi } from "vitest";
import { Naub } from "../src/Naub";
import { PhysicsWorld } from "../src/world/PhysicsWorld";
import { Graph } from "../src/Graph";

interface FakeLayer {
  physics: PhysicsWorld;
  graph: Graph;
  naub_joined: { dispatch: ReturnType<typeof vi.fn> };
  naub_replaced: { dispatch: ReturnType<typeof vi.fn> };
  unfocus: ReturnType<typeof vi.fn>;
  get_object(id: number): any;
  objects: Record<number, any>;
}

const makeLayer = (): FakeLayer => {
  const objects: Record<number, any> = {};
  return {
    physics: new PhysicsWorld(400, 300),
    graph: new Graph({ cycle_found: { dispatch: vi.fn() } }),
    naub_joined: { dispatch: vi.fn() },
    naub_replaced: { dispatch: vi.fn() },
    unfocus: vi.fn(),
    get_object: (id: number) => objects[id],
    objects,
  };
};

// real prototype and body, no canvas or shapes, enough for the join code
const makeNaub = (layer: FakeLayer, number: number, size = 42) => {
  const naub = Object.assign(Object.create(Naub.prototype), {
    layer,
    number,
    size,
    joins: {},
    constraints: {},
    drawing_join: {},
  });
  const body = new cp.Body(1, 1);
  body.setPos(cp.vzero);
  naub.physical_body = body;
  layer.objects[number] = naub;
  return naub;
};

describe("Naub join physics", () => {
  describe("join_with", () => {
    it("links both naubs and tracks the SlideJoint constraint", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      const naub_b = makeNaub(layer, 2);

      const id = naub_a.join_with(naub_b);

      expect(id).toBeGreaterThan(0);
      expect(naub_a.joins[id]).toBe(naub_b);
      expect(naub_b.joins[id]).toBe(naub_a);
      expect(naub_a.drawing_join[id]).toBe(true);
      expect(naub_b.drawing_join[id]).toBe(false);
      expect(layer.naub_joined.dispatch).toHaveBeenCalled();
    });

    it("adds and tracks both constraints that hold the join together", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      const naub_b = makeNaub(layer, 2);

      const id = naub_a.join_with(naub_b);

      expect(layer.physics.space.constraints.length).toBe(2);
      expect(naub_a.constraints[id].map((c: any) => c.name).sort()).toEqual([
        "DampedSpring",
        "SlideJoint",
      ]);
    });

    it("returns -1 and adds nothing when the naubs are already joined", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      const naub_b = makeNaub(layer, 2);
      naub_a.join_with(naub_b);

      const before = layer.physics.space.constraints.length;
      expect(naub_a.join_with(naub_b)).toBe(-1);
      expect(layer.physics.space.constraints.length).toBe(before);
    });
  });

  describe("split_join", () => {
    it("unlinks both naubs and removes both tracked constraints from the space", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      const naub_b = makeNaub(layer, 2);
      const id = naub_a.join_with(naub_b);
      const [spring, slide] = naub_a.constraints[id];

      naub_a.split_join(id);

      expect(naub_a.joins[id]).toBeUndefined();
      expect(naub_b.joins[id]).toBeUndefined();
      expect(layer.graph.joins[id]).toBeUndefined();
      expect(layer.physics.space.containsConstraint(spring)).toBe(false);
      expect(layer.physics.space.containsConstraint(slide)).toBe(false);
      expect(layer.physics.space.constraints.length).toBe(0);
    });

    it("does nothing for an id the naub does not hold", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      expect(() => naub_a.split_join(99)).not.toThrow();
    });
  });

  describe("replace_with", () => {
    it("moves the partner over to the replacement and removes itself", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1); // gets replaced
      const partner = makeNaub(layer, 2);
      const replacement = makeNaub(layer, 3);
      naub_a.join_with(partner);

      naub_a.replace_with(replacement);

      expect(naub_a.removed).toBe(true);
      expect(naub_a.is_joined_with(partner)).toBe(false);
      expect(replacement.is_joined_with(partner)).toBe(true);
      expect(layer.unfocus).toHaveBeenCalled();
      expect(layer.naub_replaced.dispatch).toHaveBeenCalledWith(
        replacement.number,
      );
    });

    it("leaves the new join between replacement and partner with working tracked constraints", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      const partner = makeNaub(layer, 2);
      const replacement = makeNaub(layer, 3);
      naub_a.join_with(partner);

      naub_a.replace_with(replacement);

      const newId = Object.keys(replacement.joins)[0];
      const [spring, slide] = replacement.constraints[newId];
      expect(slide.name).toBe("SlideJoint");
      expect(layer.physics.space.containsConstraint(spring)).toBe(true);
      expect(layer.physics.space.containsConstraint(slide)).toBe(true);
    });

    it("cleans up both old join constraints regardless of who initiated it, leaving only the new join", () => {
      const layer = makeLayer();
      const naub_a = makeNaub(layer, 1);
      const partner = makeNaub(layer, 2);
      const replacement = makeNaub(layer, 3);
      const oldId = naub_a.join_with(partner);
      const [oldSpring, oldSlide] = naub_a.constraints[oldId];

      naub_a.replace_with(replacement);

      expect(layer.physics.space.containsConstraint(oldSpring)).toBe(false);
      expect(layer.physics.space.containsConstraint(oldSlide)).toBe(false);
      expect(layer.physics.space.constraints.length).toBe(2);
    });
  });

  describe("attracted_to", () => {
    it("adds a center-join constraint to the space", () => {
      const layer = makeLayer();
      const naub = makeNaub(layer, 1);
      const center = new cp.Vect(200, 150);

      naub.attracted_to(center);

      expect(naub.centerjoin.centerjoin).toBe(true);
      expect(layer.physics.space.containsConstraint(naub.centerjoin)).toBe(
        true,
      );
      expect(naub.constraints.center).toBe(naub.centerjoin);
    });

    it("warns and does not add a second constraint when already attached", () => {
      const layer = makeLayer();
      const naub = makeNaub(layer, 1);
      const warn = vi.spyOn(console, "warn").mockImplementation(() => {});

      naub.attracted_to(new cp.Vect(200, 150));
      const before = layer.physics.space.constraints.length;
      naub.attracted_to(new cp.Vect(10, 10));

      expect(layer.physics.space.constraints.length).toBe(before);
      expect(warn).toHaveBeenCalled();
      warn.mockRestore();
    });
  });
});
