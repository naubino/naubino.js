import { beforeEach, describe, expect, it, vi } from "vitest";
import { Graph } from "../src/game/Graph";

interface MinimalNaub {
  number: number;
}

interface Layer {
  cycle_found: { dispatch: ReturnType<typeof vi.fn> };
}

const naub = (number: number): MinimalNaub => ({ number });

const makeLayer = (): Layer => ({ cycle_found: { dispatch: vi.fn() } });

const makeGraph = (layer: Layer = makeLayer()): Graph => new Graph(layer);

const build = (graph: Graph, pairs: [number, number][]): number[] =>
  pairs.map((pair) => graph.add_join(naub(pair[0]), naub(pair[1])));

const dispatchedLists = (layer: Layer): number[][] =>
  layer.cycle_found.dispatch.mock.calls.map((call: unknown[]) =>
    call[0] as number[]
  );

describe("Graph", () => {
  describe("joins", () => {
    let graph: Graph;
    beforeEach(() => {
      graph = makeGraph();
    });

    it("hands out sequential join ids starting at 1", () => {
      expect(build(graph, [[1, 2], [2, 3]])).toEqual([1, 2]);
    });

    it("lists every naub once in naubs", () => {
      build(graph, [[1, 2], [2, 3], [3, 1]]);
      expect(graph.naubs).toEqual([1, 2, 3]);
    });

    it("remove_join drops the join and the naubs left without joins", () => {
      build(graph, [[1, 2], [2, 3]]);
      graph.remove_join(2);
      expect(graph.joins).toEqual({ 1: [1, 2] });
      expect(graph.naubs).toEqual([1, 2]);
    });

    it("remove_join keeps a naub that still has another join", () => {
      build(graph, [[1, 2], [1, 3]]);
      graph.remove_join(1);
      expect(graph.naubs).toEqual([1, 3]);
    });

    it("remove_join does not reuse the removed id", () => {
      build(graph, [[1, 2], [2, 3]]);
      graph.remove_join(1);
      expect(graph.add_join(naub(3), naub(4))).toBe(3);
    });

    it("remove_join with an unknown id changes nothing", () => {
      build(graph, [[1, 2]]);
      graph.remove_join(99);
      expect(graph.joins).toEqual({ 1: [1, 2] });
      expect(graph.naubs).toEqual([1, 2]);
    });

    it("clear resets joins, naubs and the id sequence", () => {
      build(graph, [[1, 2], [2, 3]]);
      graph.clear();
      expect(graph.joins).toEqual({});
      expect(graph.naubs).toEqual([]);
      expect(graph.add_join(naub(5), naub(6))).toBe(1);
    });
  });

  describe("partners", () => {
    let graph: Graph;
    beforeEach(() => {
      graph = makeGraph();
    });

    it("returns the naubs joined to the given naub", () => {
      build(graph, [[1, 2], [1, 3], [2, 3]]);
      expect(graph.partners(1)).toEqual([2, 3]);
    });

    it("excludes joins that contain pre", () => {
      build(graph, [[1, 2], [1, 3], [2, 3]]);
      expect(graph.partners(1, 2)).toEqual([3]);
      expect(graph.partners(2, 3)).toEqual([1]);
    });

    it("returns an empty list for a naub without joins", () => {
      build(graph, [[1, 2]]);
      expect(graph.partners(42)).toEqual([]);
    });

    // quirk: a self join [n, n] makes n its own partner
    it("lists a self-join as its own partner", () => {
      build(graph, [[1, 1]]);
      expect(graph.partners(1)).toEqual([1]);
    });
  });

  describe("tree", () => {
    let graph: Graph;
    beforeEach(() => {
      graph = makeGraph();
    });

    // quirk: the start naub ends up in its own tree once it has a partner,
    // the walk comes back to it
    it("returns every naub reachable from the start, including the start", () => {
      build(graph, [[1, 2], [2, 3]]);
      expect(graph.tree(1)).toEqual([2, 1, 3]);
    });

    it("returns every naub of a cycle from a middle naub", () => {
      build(graph, [[1, 2], [2, 3], [3, 1]]);
      expect(graph.tree(2)).toEqual([1, 2, 3]);
    });

    it("leaves out naubs of other components", () => {
      build(graph, [[1, 2], [3, 4]]);
      expect(graph.tree(1)).toEqual([2, 1]);
    });

    it("returns an empty list for a naub without joins", () => {
      build(graph, [[1, 2]]);
      expect(graph.tree(42)).toEqual([]);
    });
  });

  describe("cycle_test", () => {
    let layer: Layer;
    let graph: Graph;
    beforeEach(() => {
      layer = makeLayer();
      graph = makeGraph(layer);
    });

    it("returns undefined", () => {
      build(graph, [[1, 2], [2, 3], [3, 1]]);
      expect(graph.cycle_test(1)).toBeUndefined();
    });

    it("does not dispatch for a chain", () => {
      build(graph, [[1, 2], [2, 3]]);
      graph.cycle_test(1);
      expect(dispatchedLists(layer)).toEqual([]);
    });

    it("dispatches a triangle rotated to start at first", () => {
      build(graph, [[1, 2], [2, 3], [3, 1]]);
      graph.cycle_test(2);
      expect(dispatchedLists(layer)).toEqual([[2, 3, 1]]);
    });

    it("dispatches a square with all four naubs when no first is given", () => {
      build(graph, [[1, 2], [2, 3], [3, 4], [4, 1]]);
      graph.cycle_test();
      expect(dispatchedLists(layer)).toEqual([[1, 2, 3, 4]]);
    });

    it("leaves a dangling tail out of the dispatched cycle", () => {
      build(graph, [[1, 2], [2, 3], [3, 1], [3, 4]]);
      graph.cycle_test(2);

      expect(dispatchedLists(layer)).toEqual([[2, 3, 1]]);
    });

    it("dispatches the cycle unrotated when first is not in it", () => {
      build(graph, [[1, 2], [2, 3], [3, 1], [3, 4]]);
      graph.cycle_test(4);
      expect(dispatchedLists(layer)).toEqual([[1, 2, 3]]);
    });

    it("dispatches each of two separate triangles once", () => {
      build(graph, [[1, 2], [2, 3], [3, 1], [4, 5], [5, 6], [6, 4]]);
      graph.cycle_test();
      expect(dispatchedLists(layer)).toEqual([[1, 2, 3], [4, 5, 6]]);
    });

    // quirk: two joins between the same pair are no cycle,
    // partners(naub, pre) drops every join containing pre
    it("does not report parallel joins as a cycle", () => {
      build(graph, [[1, 2], [1, 2]]);
      graph.cycle_test();
      expect(dispatchedLists(layer)).toEqual([]);
    });
  });
});
